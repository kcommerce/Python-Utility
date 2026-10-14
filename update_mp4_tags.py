#!/usr/bin/env python3
"""
update_mp4_tags.py - write Artist / Title / Album tags into MP4 files that ReelBox already downloaded.

For every  <profile folder>/<video id> - <title>.mp4  it creates a tagged copy in  <profile>-update/

    Artist = the profile folder name              e.g. ks.anime_v2
    Title  = the text after "<id> - " in the name e.g. สัประยุทธ์ทะลุฟ้า ตอนที่ 207 ซับไทย #สัประยุทธ์ทะลุฟ้า #ศึกร
    Album  = profile + time stamp                 e.g. ks.anime_v2 2026-10-14 15:42:10
             (or your own text with --album, see below)

The original files are never modified. Video and audio are not re-encoded (only the tag block changes).

Usage
    python3 update_mp4_tags.py ~/Downloads/Reelbox-videos/ks.anime_v2
    python3 update_mp4_tags.py ~/Downloads/Reelbox-videos            # every profile folder inside
    python3 update_mp4_tags.py ~/Downloads/Reelbox-videos/ks.anime_v2 --dry-run
    python3 update_mp4_tags.py ~/Downloads/Reelbox-videos/ks.anime_v2 --album "Anime Collection"
    python3 update_mp4_tags.py ~/Downloads/Reelbox-videos --album "{profile} - Season 1"   # {profile} and {time} are replaced

Requires:  pip3 install mutagen
"""
import argparse
import os
import re
import shutil
import sys
import unicodedata
from datetime import datetime
from pathlib import Path

try:
    from mutagen.mp4 import MP4
except ImportError:
    sys.exit("This script needs the 'mutagen' package. Install it with:\n    pip3 install mutagen")

# "<video id> - <title>.mp4"  (ReelBox names files this way; the title part is cut at 60 characters)
NAME_RE = re.compile(r"^(\d{10,})\s+-\s+(.*)$")


def clean(text: str) -> str:
    return re.sub(r"\s+", " ", unicodedata.normalize("NFC", text)).strip()


def parse_name(stem: str, profile: str):
    """Return (video_id, title) from a file name without extension."""
    m = NAME_RE.match(stem)
    if m:
        vid, title = m.group(1), clean(m.group(2))
    else:
        vid, title = "", clean(stem)
    if not title:
        title = f"{profile} {vid}".strip()
    return vid, title


def mp4_files(folder: Path):
    return sorted(
        f for f in folder.iterdir()
        if f.is_file() and f.suffix.lower() == ".mp4" and not f.name.startswith(".")
    )


def find_profile_folders(paths, suffix):
    """A path can be a profile folder (contains .mp4 files) or a root holding several profile folders."""
    found = []
    for p in paths:
        p = Path(p).expanduser().resolve()
        if not p.is_dir():
            print(f"! Not a folder, skipped: {p}")
            continue
        if mp4_files(p):
            if p.name.endswith(suffix):
                print(f"! Looks like an output folder, skipped: {p}")
            else:
                found.append(p)
            continue
        subs = [d for d in sorted(p.iterdir())
                if d.is_dir() and not d.name.startswith(".") and not d.name.endswith(suffix) and mp4_files(d)]
        if not subs:
            print(f"! No .mp4 files found in: {p}")
        found.extend(subs)
    return found


def write_tags(path: Path, artist: str, title: str, album: str):
    mp4 = MP4(str(path))
    if mp4.tags is None:
        mp4.add_tags()
    mp4.tags["\xa9ART"] = [artist]    # Artist
    mp4.tags["\xa9nam"] = [title]     # Title
    mp4.tags["\xa9alb"] = [album]     # Album
    mp4.save()
    # read back to make sure the tags really are in the file
    check = MP4(str(path)).tags
    if check.get("\xa9ART") != [artist] or check.get("\xa9nam") != [title] or check.get("\xa9alb") != [album]:
        raise RuntimeError("tags could not be verified after writing")


def process_folder(folder: Path, args, run_time: datetime):
    profile = folder.name
    out_dir = (Path(args.out_root).expanduser().resolve() if args.out_root else folder.parent) / f"{profile}{args.suffix}"
    files = mp4_files(folder)
    print(f"\n== {profile}: {len(files)} file(s)  ->  {out_dir}")
    if not args.dry_run:
        out_dir.mkdir(parents=True, exist_ok=True)

    ok = skipped = failed = 0
    for i, src in enumerate(files, 1):
        _, title = parse_name(src.stem, profile)
        when = datetime.fromtimestamp(src.stat().st_mtime) if args.album_time == "mtime" else run_time
        stamp = f"{when:%Y-%m-%d %H:%M:%S}"
        if args.album is not None:
            # --album overrides the default; {profile} and {time} may be used as placeholders
            album = args.album.replace("{profile}", profile).replace("{time}", stamp)
        else:
            album = f"{profile} {stamp}"
        dst = out_dir / src.name
        label = f"[{i}/{len(files)}]"

        if dst.exists() and not args.overwrite:
            print(f"{label} exists, skipped: {dst.name}")
            skipped += 1
            continue
        if args.dry_run:
            print(f"{label} {src.name}\n       Artist={profile} | Title={title} | Album={album}")
            ok += 1
            continue
        try:
            st = src.stat()
            shutil.copy2(src, dst)                      # the original stays untouched
            write_tags(dst, profile, title, album)
            os.utime(dst, (st.st_atime, st.st_mtime))   # keep the original file date
            print(f"{label} OK  {title[:70]}")
            ok += 1
        except Exception as e:                          # noqa: BLE001 - report and continue with the next file
            failed += 1
            print(f"{label} FAILED {src.name}: {e}")
            if dst.exists():
                dst.unlink()
    return ok, skipped, failed


def main():
    ap = argparse.ArgumentParser(description="Write Artist/Title/Album tags into downloaded MP4 files (to a new <profile>-update folder).")
    ap.add_argument("paths", nargs="+", help="a profile folder, or a folder that contains several profile folders")
    ap.add_argument("--suffix", default="-update", help="suffix of the output folder name (default: -update)")
    ap.add_argument("--out-root", help="create the <profile>-update folders here instead of next to each profile folder")
    ap.add_argument("--album", help='set the Album tag yourself instead of "<profile> <time stamp>". '
                                    'Placeholders: {profile} = folder name, {time} = time stamp. Example: --album "{profile} - Season 1"')
    ap.add_argument("--album-time", choices=["now", "mtime"], default="now",
                    help="time stamp used in the default album and in {time}: the time of this run (default) or each file's own modified date")
    ap.add_argument("--overwrite", action="store_true", help="replace files that already exist in the output folder")
    ap.add_argument("--dry-run", action="store_true", help="show what would be written, change nothing")
    args = ap.parse_args()

    if args.album is not None and not args.album.strip():
        sys.exit("--album must not be empty.")
    folders = find_profile_folders(args.paths, args.suffix)
    if not folders:
        sys.exit("Nothing to do.")

    run_time = datetime.now().replace(microsecond=0)
    total = [0, 0, 0]
    for f in folders:
        for k, v in enumerate(process_folder(f, args, run_time)):
            total[k] += v
    print(f"\nDone{' (dry run)' if args.dry_run else ''}: {total[0]} tagged, {total[1]} skipped, {total[2]} failed.")
    sys.exit(1 if total[2] else 0)


if __name__ == "__main__":
    main()
