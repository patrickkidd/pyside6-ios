"""Strip the N_PEXT (private external) bit from all nlist entries in a Mach-O .o or .a file.

This makes hidden-visibility symbols into regular external symbols so they can be
exported from a dynamic library. Operates in-place on the file.

Usage: python globalize_symbols.py <file.a|file.o> [file2.a ...]
"""

import struct
import sys
from pathlib import Path

# Mach-O constants
MH_MAGIC_64 = 0xFEEDFACF
LC_SYMTAB = 0x02
N_PEXT = 0x10
N_EXT = 0x01

# ar archive constants
AR_MAGIC = b"!<arch>\n"
AR_HEADER_SIZE = 60


def patch_macho(data: bytearray, offset: int = 0) -> int:
    magic = struct.unpack_from("<I", data, offset)[0]
    if magic != MH_MAGIC_64:
        return 0

    ncmds = struct.unpack_from("<I", data, offset + 16)[0]
    pos = offset + 32  # skip mach_header_64

    patched = 0
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from("<II", data, pos)
        if cmd == LC_SYMTAB:
            symoff, nsyms, stroff, strsize = struct.unpack_from("<IIII", data, pos + 8)
            symoff += offset
            for i in range(nsyms):
                entry = symoff + i * 16  # nlist_64 is 16 bytes
                n_type = data[entry + 4]
                if (n_type & N_PEXT) and (n_type & N_EXT):
                    data[entry + 4] = n_type & ~N_PEXT
                    patched += 1
        pos += cmdsize

    return patched


def patch_archive(path: Path) -> int:
    data = bytearray(path.read_bytes())
    if not data[:8] == AR_MAGIC:
        return patch_macho(data)

    patched = 0
    pos = 8
    while pos < len(data):
        if pos % 2 == 1:
            pos += 1
        if pos + AR_HEADER_SIZE > len(data):
            break

        header = data[pos:pos + AR_HEADER_SIZE]
        size_str = header[48:58].strip()
        member_size = int(size_str)
        member_start = pos + AR_HEADER_SIZE

        # Handle BSD extended names: "#1/<length>" means first N bytes are the name
        name_field = header[:16].strip().decode("ascii", errors="replace")
        name_len = int(name_field[3:]) if name_field.startswith("#1/") else 0
        obj_start = member_start + name_len

        if obj_start + 4 <= len(data):
            magic_check = struct.unpack_from("<I", data, obj_start)[0]
            if magic_check == MH_MAGIC_64:
                patched += patch_macho(data, obj_start)

        pos = member_start + member_size

    path.write_bytes(data)
    return patched


if __name__ == "__main__":
    total = 0
    for arg in sys.argv[1:]:
        p = Path(arg)
        n = patch_archive(p)
        total += n
    print(f"Globalized {total} symbols across {len(sys.argv) - 1} files")
