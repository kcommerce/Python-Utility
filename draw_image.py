from __future__ import annotations

import argparse
import os
import sys
import re
from PIL import Image, ImageDraw, ImageFont

INPUT_FILENAME = "input_image.jpg"

# ฟอนต์มาตรฐานของ macOS และระบบทั่วไป (รองรับไทย-อังกฤษ)
FONT_CANDIDATES = [
    ("/System/Library/Fonts/Helvetica.ttc", "Helvetica (English)"),
    ("/System/Library/Fonts/Supplemental/Arial.ttf", "Arial (English/Unicode)"),
    ("/System/Library/Fonts/Supplemental/Arial Unicode.ttf", "Arial Unicode (Multilingual/Thai)"),
    ("/Library/Fonts/Arial Unicode.ttf", "Arial Unicode Fallback"),
    ("/System/Library/Fonts/Supplemental/Thonburi.ttc", "Thonburi (macOS Thai/English)"),
    ("/System/Library/Fonts/Supplemental/SukhumvitSet.ttc", "Sukhumvit Set (macOS Thai/English)"),
    ("/System/Library/Fonts/Supplemental/Ayuthaya.ttf", "Ayuthaya (macOS Thai Monospace)"),
    ("/System/Library/Fonts/Supplemental/Sathu.ttf", "Sathu (macOS Thai)"),
    ("/System/Library/Fonts/Supplemental/Comic Sans MS.ttf", "Comic Sans MS"),
]

AVAILABLE_FONTS: list[tuple[str | None, str]] = [(None, "Pillow Default Font")]
for path, name in FONT_CANDIDATES:
    if os.path.exists(path):
        AVAILABLE_FONTS.append((path, name))


def contains_thai(text: str) -> bool:
    """ตรวจสอบตัวอักษรภาษาไทย"""
    return bool(re.search(r"[\u0e00-\u0e7f]", text))


def get_default_thai_font_index() -> int:
    """เลือกดัชนีฟอนต์ไทยอัตโนมัติ"""
    for idx, (_, name) in enumerate(AVAILABLE_FONTS):
        if any(keyword in name for keyword in ["Thonburi", "Sukhumvit", "Arial Unicode"]):
            return idx
    return 0


def segment_text(text: str) -> list[str]:
    """ตัดคำเพื่อรองรับการขึ้นบรรทัดใหม่ภาษาไทย"""
    if contains_thai(text):
        try:
            from pythainlp.tokenize import word_tokenize
            return word_tokenize(text, engine="newmm", keep_whitespace=True)
        except ImportError:
            pass
    tokens = re.findall(r"\S+|\s+", text)
    return tokens if tokens else [text]


def wrap_paragraph(
    paragraph: str,
    font: ImageFont.ImageFont,
    max_width: int,
    draw: ImageDraw.ImageDraw,
    indent_px: int = 0,
) -> list[tuple[str, bool]]:
    """ตัดคำข้อความภายใน 1 ย่อหน้า พร้อมคืนค่า tuple (ข้อความ, เป็นบรรทัดแรกของย่อหน้าหรือไม่)"""
    if not paragraph.strip():
        return [("", False)]

    tokens = segment_text(paragraph)
    lines: list[tuple[str, bool]] = []
    current_line = ""
    is_first_line = True

    for token in tokens:
        test_line = current_line + token
        box = draw.textbbox((0, 0), test_line, font=font)
        token_w = box[2] - box[0]

        # บรรทัดแรกหักลบระยะย่อหน้าออกจากความกว้างที่รองรับได้
        current_max_w = (max_width - indent_px) if is_first_line else max_width

        if token_w <= current_max_w:
            current_line = test_line
        else:
            if current_line.strip():
                lines.append((current_line.strip(), is_first_line))
                is_first_line = False
            current_line = token.lstrip()

    if current_line.strip():
        lines.append((current_line.strip(), is_first_line))

    return lines if lines else [("", False)]


def wrap_full_text(
    text: str,
    font: ImageFont.ImageFont,
    max_width: int,
    draw: ImageDraw.ImageDraw,
    indent_px: int = 0,
) -> list[tuple[str, bool]]:
    """แยกย่อหน้าและจัดบรรทัดพร้อมระบุบรรทัดที่ต้องเยื้องย่อหน้า"""
    text = text.replace("\\n", "\n")
    paragraphs = text.splitlines()
    all_lines: list[tuple[str, bool]] = []

    for para in paragraphs:
        if not para.strip():
            all_lines.append(("", False))
        else:
            all_lines.extend(wrap_paragraph(para, font, max_width, draw, indent_px))

    return all_lines


def list_fonts() -> None:
    print("Available Fonts:")
    for idx, (_, name) in enumerate(AVAILABLE_FONTS):
        print(f"  [{idx}] {name}")


def load_font(font_path: str | None, size: int) -> ImageFont.ImageFont | ImageFont.FreeTypeFont:
    if font_path:
        try:
            return ImageFont.truetype(font_path, size)
        except Exception:
            pass
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def get_indent_width(font: ImageFont.ImageFont, draw: ImageDraw.ImageDraw, char_count: int = 2) -> int:
    """คำนวณระยะพิกเซลชดเชยตามจำนวนตัวอักษร (ค่าเฉลี่ยตัวอักษร ก หรือ n)"""
    sample = "ก" if hasattr(font, "getlength") else "n"
    box = draw.textbbox((0, 0), sample * char_count, font=font)
    return box[2] - box[0]


def draw_text_in_box(
    text: str,
    font_index: int | None = None,
    font_size: int | None = None,
    align: str = "left",
    indent_chars: int = 2,
    output_path: str = "output.jpg",
) -> None:
    if font_index is None:
        font_index = get_default_thai_font_index() if contains_thai(text) else 0

    if not (0 <= font_index < len(AVAILABLE_FONTS)):
        print(f"Error: Invalid font index {font_index}. Choose between 0 and {len(AVAILABLE_FONTS) - 1}.")
        sys.exit(1)

    font_path, _ = AVAILABLE_FONTS[font_index]

    with Image.open(INPUT_FILENAME).convert("RGB") as img:
        draw = ImageDraw.Draw(img)
        w, h = img.size

        # พิกัดกล่องสีขาวด้านขวา
        box_x1 = int(w * 0.32)
        box_y1 = int(h * 0.06)
        box_x2 = int(w * 0.97)
        box_y2 = int(h * 0.88)

        # ระยะขอบด้านในกล่อง (Padding)
        pad_x = int((box_x2 - box_x1) * 0.05)
        pad_y = int((box_y2 - box_y1) * 0.06)

        target_w = (box_x2 - box_x1) - (2 * pad_x)
        target_h = (box_y2 - box_y1) - (2 * pad_y)

        # 1. คำนวณขนาด Font และ Auto-fit
        if font_size is None:
            current_size = 44
            while current_size >= 14:
                font = load_font(font_path, current_size)
                indent_px = get_indent_width(font, draw, indent_chars)
                lines = wrap_full_text(text, font, target_w, draw, indent_px)

                line_spacing = int(current_size * 0.35)
                line_height = current_size + line_spacing
                total_text_h = len(lines) * line_height

                if total_text_h <= target_h:
                    break
                current_size -= 2
        else:
            font = load_font(font_path, font_size)
            indent_px = get_indent_width(font, draw, indent_chars)
            lines = wrap_full_text(text, font, target_w, draw, indent_px)
            current_size = font_size

        line_spacing = int(current_size * 0.35)
        line_height = current_size + line_spacing

        # 2. จุดเริ่มเขียนจากบนลงล่าง
        start_x = box_x1 + pad_x
        current_y = box_y1 + pad_y

        for line, is_first_line in lines:
            if current_y + line_height > box_y2 - pad_y:
                break

            if not line:
                current_y += line_height
                continue

            line_box = draw.textbbox((0, 0), line, font=font)
            line_w = line_box[2] - line_box[0]

            # เพิ่มการชดเชยระยะเยื้อง 2 ตัวอักษรเฉพาะบรรทัดแรกของย่อหน้า
            current_indent = indent_px if (is_first_line and align == "left") else 0

            if align == "center":
                draw_x = start_x + (target_w - line_w) // 2
            elif align == "right":
                draw_x = start_x + (target_w - line_w)
            else:
                draw_x = start_x + current_indent

            draw.text((draw_x, current_y), line, fill=(35, 35, 45), font=font)
            current_y += line_height

        img.save(output_path, "JPEG", quality=95)
        print(f"Saved: {output_path}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Draw text starting from top to bottom with paragraph indentation.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""ตัวอย่างการใช้งาน:
  python3 draw_image.py "ย่อหน้าที่หนึ่ง มีการเยื้องเข้า 2 ตัวอักษร\\n\\nย่อหน้าที่สอง ก็จะเยื้องเข้า 2 ตัวอักษรเช่นกัน"
  python3 draw_image.py "ทดสอบข้อความ" --indent 2
        """,
    )

    parser.add_argument("text", nargs="?", help="ข้อความที่ต้องการพิมพ์ (รองรับ \\n)")
    parser.add_argument("-i", "--font-index", type=int, default=None, help="Font index (เลือกฟอนต์ไทยอัตโนมัติหากมีภาษาไทย)")
    parser.add_argument("-s", "--font-size", type=int, default=None, help="ขนาดฟอนต์ (pt)")
    parser.add_argument("--indent", type=int, default=2, help="จำนวนตัวอักษรที่ต้องการเยื้องย่อหน้า (default: 2)")
    parser.add_argument("--align", choices=["left", "center", "right"], default="left", help="การจัดแนวแนวนอน (default: left)")
    parser.add_argument("-o", "--output", default="output.jpg", help="ไฟล์ผลลัพธ์ (default: output.jpg)")
    parser.add_argument("--list-fonts", action="store_true", help="แสดงรายการฟอนต์")

    args = parser.parse_args()

    if args.list_fonts:
        list_fonts()
        return

    if not args.text:
        parser.print_help()
        sys.exit(1)

    draw_text_in_box(
        text=args.text,
        font_index=args.font_index,
        font_size=args.font_size,
        align=args.align,
        indent_chars=args.indent,
        output_path=args.output,
    )


if __name__ == "__main__":
    main()
