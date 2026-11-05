"""Work around the observed glibc-version report crash in ChatGPT x64 (26.917.71314+).

Skip the optional runtime-version field using its existing no-symbol branch.
Do not disable CFI globally or change the indirect call to accept arbitrary targets.
"""
from pathlib import Path
import re
import sys


def patch(data: bytes) -> bytes:
    # Keep explicit layouts for the inspected releases. Compiler changes can
    # alter the branch width and stack layout, not just relative addresses.
    # Each variant skips the same optional field via the no-symbol branch.
    layouts = [
        (
            rb"\x48\x85\xc0\x0f\x84\x66\x01\x00\x00",
            bytes.fromhex("48 8d 9d b0 fb ff ff"),
            bytes.fromhex("e9 67 01 00 00 90"),
            0x166,
        ),
        (
            rb"\x48\x85\xc0\x74\x30",
            bytes.fromhex("4c 8d b5 b0 fb ff ff"),
            bytes.fromhex("eb 30"),
            0x30,
        ),
    ]
    guarded_call = (
        rb"\x48\x8d\x0d....\x48\x29\xc1\x48\xc1\xc9\x03"
        rb"\x48\x83\xf9\x03\x0f\x87....\xff\xd0"
    )
    candidates = []
    for prefix, expected_destination, replacement, displacement in layouts:
        signature = re.compile(prefix + guarded_call, re.DOTALL)
        for match in signature.finditer(data):
            branch = match.start() + 3
            destination = branch + len(replacement) + displacement
            if data[destination:destination + len(expected_destination)] != expected_destination:
                raise ValueError("Unexpected branch destination; refusing to patch")
            candidates.append((branch, replacement))
    if len(candidates) != 1:
        raise ValueError(
            f"Expected exactly one known instruction sequence, found {len(candidates)}; "
            "refusing to patch"
        )
    branch, replacement = candidates[0]
    # JE becomes JMP of the same width (with NOP padding for the long form).
    # The indirect call and its CFI guard remain intact but are never reached.
    return data[:branch] + replacement + data[branch + len(replacement):]



if __name__ == "__main__":
    target = Path(sys.argv[1])
    original = target.read_bytes()
    modified = patch(original)
    target.write_bytes(modified)
    print("Applied version-specific Node report workaround")
