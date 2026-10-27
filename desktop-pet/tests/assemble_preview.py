"""Assemble Godot-rendered PNG frames into a looping APNG using only stdlib."""
import argparse
import struct
import zlib
from pathlib import Path

SIGNATURE = b"\x89PNG\r\n\x1a\n"


def chunks(data):
    if data[:8] != SIGNATURE:
        raise ValueError("Not a PNG frame")
    offset = 8
    while offset < len(data):
        size = struct.unpack_from(">I", data, offset)[0]
        kind = data[offset + 4:offset + 8]
        yield kind, data[offset + 8:offset + 8 + size]
        offset += size + 12


def chunk(kind, payload):
    return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload))


def assemble(directory, output, fps):
    frames = sorted(directory.glob("frame-*.png"))
    if len(frames) < 2 or not 1 <= fps <= 60:
        raise ValueError("Need multiple frames and FPS in 1..60")
    first = list(chunks(frames[0].read_bytes()))
    header = next(payload for kind, payload in first if kind == b"IHDR")
    width, height = struct.unpack_from(">II", header)
    sequence = 0
    with output.open("wb") as stream:
        stream.write(SIGNATURE + chunk(b"IHDR", header) + chunk(b"acTL", struct.pack(">II", len(frames), 0)))
        for index, frame in enumerate(frames):
            parts = list(chunks(frame.read_bytes()))
            if next(payload for kind, payload in parts if kind == b"IHDR") != header:
                raise ValueError("Frame dimensions or pixel format differ")
            stream.write(chunk(b"fcTL", struct.pack(">IIIIIHHBB", sequence, width, height, 0, 0, 1, fps, 0, 0)))
            sequence += 1
            for kind, payload in parts:
                if kind == b"IDAT":
                    if index == 0:
                        stream.write(chunk(kind, payload))
                    else:
                        stream.write(chunk(b"fdAT", struct.pack(">I", sequence) + payload))
                        sequence += 1
        stream.write(chunk(b"IEND", b""))
    print(f"Animated preview: {len(frames)} frames, {width}x{height}, {fps} FPS, {output.stat().st_size} bytes")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--fps", type=int, default=20)
    args = parser.parse_args()
    assemble(args.directory, args.output, args.fps)
