#!/usr/bin/env python3

"""
Simple MP3 ID3v2.3 tag editor.

No third-party libraries required.

Supported:
    Title
    Artist
    Album
    Album Artist
    Genre
    Year
    Track
    Disc
    Composer
    Comment

Title from filename:
    Use --title-from-filename to automatically set the Title
    from each MP3 filename.

Examples:

    python3 mp3tag.py song.mp3 \
        --title "Black or White" \
        --artist "Michael Jackson"

    python3 mp3tag.py *.mp3 \
        --title-from-filename \
        --artist "Michael Jackson" \
        --album "Dangerous"

    python3 mp3tag.py /path/to/music \
        --title-from-filename \
        --artist "Michael Jackson"

    If both --title and --title-from-filename are specified,
    --title takes precedence.
"""

import argparse
import shutil
from pathlib import Path


# ---------------------------------------------------------
# ID3v2.3 Frame IDs
# ---------------------------------------------------------

FIELDS = {
    "title": "TIT2",
    "artist": "TPE1",
    "album": "TALB",
    "album_artist": "TPE2",
    "genre": "TCON",
    "year": "TYER",
    "track": "TRCK",
    "disc": "TPOS",
    "composer": "TCOM",
    "comment": "COMM",
}


# ---------------------------------------------------------
# Synchsafe integer
# ---------------------------------------------------------

def decode_synchsafe(data):
    """
    Decode 4-byte ID3 synchsafe integer.
    """
    if len(data) != 4:
        raise ValueError("Invalid synchsafe integer")

    return (
        (data[0] << 21)
        | (data[1] << 14)
        | (data[2] << 7)
        | data[3]
    )


def encode_synchsafe(value):
    """
    Encode integer as 4-byte ID3 synchsafe integer.
    """
    return bytes([
        (value >> 21) & 0x7F,
        (value >> 14) & 0x7F,
        (value >> 7) & 0x7F,
        value & 0x7F,
    ])


# ---------------------------------------------------------
# Text encoding
# ---------------------------------------------------------

def encode_text(text):
    """
    ID3v2.3 UTF-16 text frame.

    Encoding byte:
        1 = UTF-16
    """
    return b"\x01" + text.encode("utf-16")


def decode_text(data):
    """
    Decode a normal ID3 text frame.
    """
    if not data:
        return ""

    encoding = data[0]
    payload = data[1:]

    try:
        if encoding == 0:
            return payload.decode("latin-1").rstrip("\x00")

        if encoding == 1:
            return payload.decode("utf-16").rstrip("\x00")

        if encoding == 2:
            return payload.decode("utf-16-be").rstrip("\x00")

        if encoding == 3:
            return payload.decode("utf-8").rstrip("\x00")

    except UnicodeDecodeError:
        return ""

    return ""


# ---------------------------------------------------------
# Frame handling
# ---------------------------------------------------------

def create_text_frame(frame_id, value):
    """
    Create an ID3v2.3 text frame.
    """

    payload = encode_text(str(value))

    frame_size = len(payload)

    header = (
        frame_id.encode("ascii")
        + frame_size.to_bytes(4, "big")
        + b"\x00\x00"
    )

    return header + payload


def create_comment_frame(value):
    """
    Create COMM frame.

    UTF-16
    Language: eng
    Description: empty
    """

    text = str(value).encode("utf-16")

    payload = (
        b"\x01"      # UTF-16
        + b"eng"     # language
        + b"\x00\x00"
        + text
    )

    return (
        b"COMM"
        + len(payload).to_bytes(4, "big")
        + b"\x00\x00"
        + payload
    )


# ---------------------------------------------------------
# Read existing ID3v2 tag
# ---------------------------------------------------------

def read_id3(file_path):
    """
    Return:
        tag_bytes
        audio_offset
    """

    with open(file_path, "rb") as f:

        header = f.read(10)

        if len(header) < 10:
            return b"", 0

        if header[:3] != b"ID3":
            return b"", 0

        version_major = header[3]

        if version_major not in (3, 4):
            return b"", 0

        tag_size = decode_synchsafe(header[6:10])

        tag_data = f.read(tag_size)

        return header + tag_data, 10 + tag_size


# ---------------------------------------------------------
# Parse frames
# ---------------------------------------------------------

def parse_frames(tag):
    """
    Parse ID3v2.3/v2.4 frames.

    Returns:
        dict {frame_id: raw_frame}
    """

    frames = {}

    if not tag.startswith(b"ID3"):
        return frames

    version = tag[3]

    position = 10

    while position + 10 <= len(tag):

        header = tag[position:position + 10]

        frame_id = header[:4]

        if frame_id == b"\x00\x00\x00\x00":
            break

        try:
            frame_name = frame_id.decode("ascii")
        except UnicodeDecodeError:
            break

        if version == 4:
            frame_size = decode_synchsafe(header[4:8])
        else:
            frame_size = int.from_bytes(
                header[4:8],
                "big"
            )

        if frame_size <= 0:
            break

        end = position + 10 + frame_size

        if end > len(tag):
            break

        frames[frame_name] = tag[position:end]

        position = end

    return frames


# ---------------------------------------------------------
# Get existing value
# ---------------------------------------------------------

def get_text_frame(frame):
    """
    Extract text from an existing frame.
    """

    if len(frame) < 11:
        return ""

    return decode_text(frame[10:])


# ---------------------------------------------------------
# Build ID3 tag
# ---------------------------------------------------------

def build_tag(existing_tag, updates):
    """
    Preserve existing frames and replace requested fields.
    """

    frames = parse_frames(existing_tag)

    for field, value in updates.items():

        frame_id = FIELDS[field]

        if value is None:
            continue

        if field == "comment":
            frames[frame_id] = create_comment_frame(value)

        else:
            frames[frame_id] = create_text_frame(
                frame_id,
                value
            )

    body = b"".join(frames.values())

    # Add padding so future modifications have some room.
    padding = 4096

    total_size = len(body) + padding

    header = (
        b"ID3"
        + b"\x03\x00"       # ID3v2.3.0
        + b"\x00"           # flags
        + encode_synchsafe(total_size)
    )

    return header + body + (b"\x00" * padding)


# ---------------------------------------------------------
# Update MP3
# ---------------------------------------------------------

def update_file(file_path, updates, backup=True):

    file_path = Path(file_path)

    if file_path.suffix.lower() != ".mp3":
        print(f"SKIP: {file_path}")
        return

    try:

        existing_tag, audio_offset = read_id3(file_path)

        new_tag = build_tag(
            existing_tag,
            updates
        )

        if backup:

            backup_path = file_path.with_suffix(
                file_path.suffix + ".bak"
            )

            if not backup_path.exists():
                shutil.copy2(
                    file_path,
                    backup_path
                )

        with open(file_path, "rb") as f:

            if audio_offset:
                f.seek(audio_offset)

            audio_data = f.read()

        temp_path = file_path.with_suffix(
            ".mp3.tmp"
        )

        with open(temp_path, "wb") as f:

            f.write(new_tag)
            f.write(audio_data)

        temp_path.replace(file_path)

        print(f"✓ {file_path}")

    except Exception as e:

        print(f"✗ {file_path}")
        print(f"  Error: {e}")


# ---------------------------------------------------------
# Command line
# ---------------------------------------------------------

def main():

    parser = argparse.ArgumentParser(
        description="Simple pure-Python MP3 ID3v2.3 tag editor"
    )

    parser.add_argument(
        "files",
        nargs="+",
        help="MP3 files"
    )

    parser.add_argument("--title")

    parser.add_argument(
        "--title-from-filename",
        action="store_true",
        help="Set Title from each MP3 filename (without extension)"
    )

    parser.add_argument("--artist")
    parser.add_argument("--album")
    parser.add_argument("--album-artist")
    parser.add_argument("--genre")
    parser.add_argument("--year")
    parser.add_argument("--track")
    parser.add_argument("--disc")
    parser.add_argument("--composer")
    parser.add_argument("--comment")

    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Do not create .bak files"
    )

    args = parser.parse_args()

    # -----------------------------------------------------
    # Check title options
    # -----------------------------------------------------

    if args.title and args.title_from_filename:
        print(
            "INFO: --title specified; "
            "--title-from-filename will be ignored."
        )

    # -----------------------------------------------------
    # Common updates
    # -----------------------------------------------------

    updates = {
        "title": args.title,
        "artist": args.artist,
        "album": args.album,
        "album_artist": args.album_artist,
        "genre": args.genre,
        "year": args.year,
        "track": args.track,
        "disc": args.disc,
        "composer": args.composer,
        "comment": args.comment,
    }

    # -----------------------------------------------------
    # Expand directories to all MP3 files directly inside them.
    # Directory processing is non-recursive.
    # -----------------------------------------------------

    targets = []

    for path in args.files:

        path = Path(path)

        if path.is_dir():

            mp3_files = sorted(
                p for p in path.iterdir()
                if p.is_file()
                and p.suffix.lower() == ".mp3"
            )

            if not mp3_files:
                print(
                    f"SKIP: no MP3 files found in {path}"
                )
            else:
                targets.extend(mp3_files)

        else:
            targets.append(path)

    # -----------------------------------------------------
    # Process files
    # -----------------------------------------------------

    for file_path in targets:

        file_updates = dict(updates)

        # -------------------------------------------------
        # Set title from filename
        #
        # Example:
        #     "01 - Billie Jean.mp3"
        #
        # becomes:
        #     "01 - Billie Jean"
        # -------------------------------------------------

        if args.title_from_filename and not args.title:

            file_updates["title"] = (
                Path(file_path).stem
            )

        # Remove fields that were not supplied.
        file_updates = {
            key: value
            for key, value in file_updates.items()
            if value is not None
        }

        if not file_updates:
            parser.error(
                "At least one tag option must be specified."
            )

        update_file(
            file_path,
            file_updates,
            backup=not args.no_backup
        )


if __name__ == "__main__":
    main()
