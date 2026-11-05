#!/usr/bin/env python3

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(
        description="Convert MP4 files and rename them using a prefix and sequence."
    )
    parser.add_argument("folder", help="Folder containing source MP4 files")
    parser.add_argument("prefix", help="Prefix for output filenames")
    parser.add_argument(
        "-o", "--output",
        help="Output folder (default: <source_folder>_converted)"
    )
    parser.add_argument(
        "--digits", type=int, default=3,
        help="Number of sequence digits (default: 3)"
    )
    args = parser.parse_args()

    source = Path(args.folder).expanduser().resolve()

    if not source.is_dir():
        sys.exit(f"Error: folder not found: {source}")

    if args.digits < 1:
        sys.exit("Error: --digits must be at least 1")

    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        sys.exit("Error: FFmpeg not found. Install with: brew install ffmpeg")

    # Sort source files for consistent sequence numbering.
    files = sorted(
        (
            p for p in source.iterdir()
            if p.is_file() and p.suffix.lower() == ".mp4"
        ),
        key=lambda p: p.name.casefold()
    )

    if not files:
        sys.exit(f"No MP4 files found in: {source}")

    output = (
        Path(args.output).expanduser().resolve()
        if args.output
        else source.parent / f"{source.name}_converted"
    )

    if output == source:
        sys.exit("Error: output folder must differ from source folder.")

    output.mkdir(parents=True, exist_ok=True)

    print(f"Source: {source}")
    print(f"Output: {output}")
    print(f"Files:  {len(files)}\n")

    success = 0
    failed = 0

    for number, input_file in enumerate(files, start=1):
        filename = f"{args.prefix}_{number:0{args.digits}d}.mp4"
        output_file = output / filename

        print(f"[{number}/{len(files)}] {input_file.name}")
        print(f"  -> {filename}")

        command = [
            ffmpeg,
            "-hide_banner",
            "-loglevel", "error",
            "-n",  # Never overwrite an existing output file.
            "-i", str(input_file),
            "-map", "0:v:0",
            "-map", "0:a:0",
            "-c:v", "copy",
            "-c:a", "aac",
            "-profile:a", "aac_low",
            "-b:a", "128k",
            "-ar", "44100",
            "-ac", "2",
            "-map_metadata", "-1",
            "-map_chapters", "-1",
            "-movflags", "+faststart",
            str(output_file),
        ]

        result = subprocess.run(command)

        if result.returncode == 0 and output_file.exists():
            success += 1
            print("  OK")
        else:
            failed += 1
            print("  FAILED")

        print()

    print(f"Completed: {success}; Failed: {failed}")
    print(f"Output folder: {output}")


if __name__ == "__main__":
    main()

