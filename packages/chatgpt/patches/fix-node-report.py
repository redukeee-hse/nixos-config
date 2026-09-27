"""Work around the observed glibc-version report crash in ChatGPT 26.917.71314 x64.

Skip the optional runtime-version field using its existing no-symbol branch.
Do not disable CFI globally or change the indirect call to accept arbitrary targets.
"""
from pathlib import Path
import sys


def patch(data: bytes) -> bytes:
    signature = bytes.fromhex(
        "48 85 c0 0f 84 66 01 00 00 "
        "48 8d 0d 41 0a 1b 03 48 29 c1 48 c1 c9 03 "
        "48 83 f9 03 0f 87 56 6a 00 00 ff d0"
    )
    if data.count(signature) != 1:
        raise ValueError("Expected exactly one known instruction sequence; refusing to patch")
    branch = data.index(signature) + 3
    destination = branch + 6 + 0x166
    if data[destination:destination + 7] != bytes.fromhex("48 8d 9d b0 fb ff ff"):
        raise ValueError("Unexpected branch destination; refusing to patch")
    # Six-byte JE becomes a five-byte JMP plus NOP, preserving the destination.
    return data[:branch] + bytes.fromhex("e9 67 01 00 00 90") + data[branch + 6:]


if __name__ == "__main__":
    target = Path(sys.argv[1])
    original = target.read_bytes()
    modified = patch(original)
    target.write_bytes(modified)
    print("Applied version-specific Node report workaround")
