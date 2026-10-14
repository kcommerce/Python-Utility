#!/usr/bin/env python3
import json
import subprocess
import sys

filename = sys.argv[1] if len(sys.argv) > 1 else "video.mp4"

result = subprocess.run(
    [
        "ffprobe", "-v", "quiet",
        "-show_format",
        "-show_streams",
        "-of", "json",
        filename
    ],
    capture_output=True,
    text=True,
    check=True
)

data = json.loads(result.stdout)
fmt = data.get("format", {})
tags = fmt.get("tags", {})

def get_tag(name):
    return next(
        (v for k, v in tags.items() if k.lower() == name.lower()),
        ""
    )

print("=== Metadata ===")
for key in ("author", "album", "artist", "title"):
    print(f"{key.capitalize()}: {get_tag(key)}")

print("\n=== File Specifications ===")
print(f"File: {filename}")
print(f"Format: {fmt.get('format_name', '')}")
print(f"Duration: {float(fmt.get('duration', 0)):.2f} seconds")
print(f"File size: {int(fmt.get('size', 0)) / 1024 / 1024:.2f} MB")
print(f"Bitrate: {int(fmt.get('bit_rate', 0)) // 1000} kbps")

for stream in data.get("streams", []):
    kind = stream.get("codec_type")

    if kind == "video":
        print("\n=== Video ===")
        print(f"Codec: {stream.get('codec_name', '')}")
        print(f"Resolution: {stream.get('width', 0)}x{stream.get('height', 0)}")
        print(f"Frame rate: {stream.get('r_frame_rate', '')} fps")
        print(f"Pixel format: {stream.get('pix_fmt', '')}")
        print(f"Bitrate: {int(stream.get('bit_rate', 0) or 0) // 1000} kbps")

    elif kind == "audio":
        print("\n=== Audio ===")
        print(f"Codec: {stream.get('codec_name', '')}")
        print(f"Sample rate: {stream.get('sample_rate', '')} Hz")
        print(f"Channels: {stream.get('channels', '')}")
        print(f"Bitrate: {int(stream.get('bit_rate', 0) or 0) // 1000} kbps")
