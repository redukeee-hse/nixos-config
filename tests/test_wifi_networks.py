"""Regression checks for hidden Wi-Fi networks in the settings panel."""

import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1] / "home/example/files/config/quickshell/SettingsPages/wifi-networks.py"
spec = importlib.util.spec_from_file_location("wifi_networks", SOURCE)
wifi = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wifi)


class NetworksTest(unittest.TestCase):
    def collect(self, scan, ssid="Hidden", devices="wlan0:wifi:connected:active-uuid\n"):
        profile = f"802-11-wireless.ssid:{ssid}\n802-11-wireless-security.key-mgmt:wpa-psk\n"
        with patch.object(wifi, "nmcli", side_effect=[devices, profile, scan]):
            return wifi.networks()

    def test_hidden_absent_from_scan(self):
        result = self.collect(":Guest:80::wlan0\n")
        self.assertEqual([n["ssid"] for n in result], ["Hidden", "Guest"])
        self.assertTrue(result[0]["connected"])
        self.assertTrue(result[0]["secured"])
        self.assertEqual(result[0]["uuid"], "active-uuid")
        self.assertFalse(result[1]["connected"])

    def test_empty_or_stale_active_ap_name(self):
        for cached_name in ("", "Old SSID"):
            with self.subTest(cached_name=cached_name):
                result = self.collect(f"*:{cached_name}:75:WPA2:wlan0\n")
                self.assertEqual(len(result), 1)
                self.assertEqual(result[0]["ssid"], "Hidden")
                self.assertEqual(result[0]["signal"], 75)

    def test_escaped_ssid_and_duplicates(self):
        result = self.collect(
            "*:Room\\: A\\\\B:50:WPA2:wlan0\n:Room\\: A\\\\B:90:WPA2:wlan0\n",
            ssid="Room\\: A\\\\B",
        )
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["ssid"], "Room: A\\B")
        self.assertEqual(result[0]["signal"], 90)
        self.assertTrue(result[0]["connected"])

    def test_disconnected_device_does_not_inherit_cached_connected_flag(self):
        with patch.object(wifi, "nmcli", side_effect=[
            "wlan0:wifi:disconnected:\n",
            "*:Old SSID:80:WPA2:wlan0\n",
        ]):
            result = wifi.networks()
        self.assertFalse(result[0]["connected"])
        self.assertEqual(result[0]["uuid"], "")


if __name__ == "__main__":
    unittest.main()
