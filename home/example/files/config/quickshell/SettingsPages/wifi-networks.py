"""Combine Wi-Fi scan results with authoritative active connection profiles."""

import json
import os
import subprocess


def nmcli(*args):
    return subprocess.check_output(
        ["nmcli", *args], text=True, env={**os.environ, "LC_ALL": "C"}, timeout=15
    )


def fields(line):
    """Decode nmcli terse fields, including escaped colons and backslashes."""
    result, current, escaped = [], [], False
    for char in line:
        if escaped:
            current.append(char)
            escaped = False
        elif char == "\\":
            escaped = True
        elif char == ":":
            result.append("".join(current))
            current = []
        else:
            current.append(char)
    if escaped:
        current.append("\\")
    result.append("".join(current))
    return result


def networks():
    active = {}
    devices = nmcli("-t", "-f", "DEVICE,TYPE,STATE,CON-UUID", "device")
    for line in devices.splitlines():
        device, kind, state, uuid = fields(line)
        if kind != "wifi" or state != "connected" or not uuid:
            continue
        # A profile's display name can differ from its actual SSID. Never use
        # connection.id or a cached access-point name as the connected SSID.
        details = nmcli(
            "-t", "-f", "802-11-wireless.ssid,802-11-wireless-security.key-mgmt",
            "connection", "show", "uuid", uuid,
        )
        props = dict(fields(row) for row in details.splitlines())
        ssid = props.get("802-11-wireless.ssid", "")
        if not ssid:
            continue
        security = props.get("802-11-wireless-security.key-mgmt", "")
        active[device] = dict(
            ssid=ssid, signal=0, secured=security not in ("", "--"),
            connected=True, uuid=uuid,
        )

    by_ssid = {}
    scan = nmcli(
        "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY,DEVICE",
        "device", "wifi", "list",
    )
    for line in scan.splitlines():
        in_use, ssid, signal, security, device = fields(line)
        if in_use == "*" and device in active:
            # Hidden APs can have an empty or stale SSID in the scan cache.
            ssid = active[device]["ssid"]
            active[device]["signal"] = int(signal or 0)
        if not ssid:
            continue
        net = by_ssid.setdefault(ssid, dict(
            ssid=ssid, signal=0, secured=False, connected=False, uuid="",
        ))
        net["signal"] = max(net["signal"], int(signal or 0))
        net["secured"] |= security not in ("", "--")

    # Include active hidden networks even when the scan omits them entirely.
    for net in active.values():
        scanned = by_ssid.get(net["ssid"])
        if scanned:
            net["signal"] = max(net["signal"], scanned["signal"])
        by_ssid[net["ssid"]] = net
    return sorted(by_ssid.values(), key=lambda net: (not net["connected"], -net["signal"]))


if __name__ == "__main__":
    print(json.dumps(networks(), ensure_ascii=False))
