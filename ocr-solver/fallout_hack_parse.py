#!/usr/bin/env python3
"""
Parse Fallout terminal hacking screens and extract the candidate words.

How it works:
- OCR the screen with Tesseract, keeping addresses like 0xF4F0.
- For each OCR line, split into: left address + left data + right address + right data
- Sort rows by address and reconstruct the "memory stream" (left data then right data)
- Extract contiguous A-Z sequences, infer fixed word length (mode) unless provided
- Output words (unique, in first-seen order)

Requirements:
- pip install opencv-python pytesseract
- System Tesseract binary installed (e.g. `tesseract` in PATH)
"""

import argparse
import re
import sys
from collections import Counter, OrderedDict

import cv2
import numpy as np
import pytesseract


ADDR_RE = re.compile(r"0x[0-9A-Fa-f]{4}")
UPWORD_RE = re.compile(r"[A-Z]+")


def preprocess_for_ocr(bgr: np.ndarray, scale: int = 3) -> np.ndarray:
    """Preprocess image to improve OCR of green terminal text."""
    # Upscale (helps OCR)
    h, w = bgr.shape[:2]
    bgr = cv2.resize(bgr, (w * scale, h * scale), interpolation=cv2.INTER_CUBIC)

    # Grayscale
    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)

    # Contrast enhancement (robust on glow/scanlines)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    gray = clahe.apply(gray)

    # Optional: slight blur to reduce scanline noise
    gray = cv2.GaussianBlur(gray, (3, 3), 0)

    # Threshold
    _, th = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    # Morphological cleanup
    kernel = np.ones((2, 2), np.uint8)
    th = cv2.morphologyEx(th, cv2.MORPH_OPEN, kernel, iterations=1)
    th = cv2.morphologyEx(th, cv2.MORPH_CLOSE, kernel, iterations=1)

    return th


def ocr_text(img_bin: np.ndarray) -> str:
    # NOTE: do NOT include a literal double-quote in this whitelist,
    # because it breaks shlex parsing of the config string.
    whitelist = (
        "0123456789abcdefABCDEFxX"
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "[]{}()<>"
        "!@#$%^&*-_=+;:'.,?/\\|`~"   # removed the double-quote
    )
    config = f'--oem 3 --psm 6 -c tessedit_char_whitelist="{whitelist}"'
    return pytesseract.image_to_string(img_bin, config=config)


def parse_rows(ocr: str):
    """
    Parse OCR lines into rows of (addr:int, left_data:str, right_data:str).

    Each terminal row typically looks like:
      0xF4F0 <12 chars>  0xF5BC <12 chars>
    """
    rows = []
    for raw_line in ocr.splitlines():
        line = raw_line.strip()
        if not line:
            continue

        addrs = list(ADDR_RE.finditer(line))
        if len(addrs) < 2:
            continue

        a1 = addrs[0]
        a2 = addrs[1]
        addr1 = int(a1.group(0), 16)
        addr2 = int(a2.group(0), 16)

        left_data = line[a1.end():a2.start()]
        right_data = line[a2.end():]

        # Remove spaces OCR may insert
        left_data = re.sub(r"\s+", "", left_data)
        right_data = re.sub(r"\s+", "", right_data)

        # Prefer the left address as the "row id" (Fallout increments by 0x0C per row)
        # but keep the second address in case you want to sanity-check later.
        rows.append((addr1, left_data, right_data, addr2))
    return rows


def infer_column_width(rows) -> int:
    """
    Infer typical column width (the number of characters after each address).
    Fallout screens commonly use 12 chars per side per row.
    """
    lens = []
    for _, l, r, _ in rows:
        if l:
            lens.append(len(l))
        if r:
            lens.append(len(r))
    if not lens:
        return 12
    # Use a robust mode: consider only reasonable widths
    filtered = [x for x in lens if 6 <= x <= 24]
    if not filtered:
        filtered = lens
    counts = Counter(filtered)
    return counts.most_common(1)[0][0]


def reconstruct_stream(rows, col_width: int) -> str:
    """
    Sort by address and build the continuous memory stream:
    for each row: left_data (padded/truncated) + right_data (padded/truncated)
    """
    rows_sorted = sorted(rows, key=lambda t: t[0])

    stream_parts = []
    for _, left, right, _addr2 in rows_sorted:
        left = (left[:col_width]).ljust(col_width, "?")
        right = (right[:col_width]).ljust(col_width, "?")
        stream_parts.append(left)
        stream_parts.append(right)
    return "".join(stream_parts)


def extract_words(stream: str, word_len: int | None = None):
    """
    Extract contiguous uppercase words from the reconstructed stream.
    If word_len is None, infer as the most common length among found words.
    """
    candidates = [m.group(0) for m in UPWORD_RE.finditer(stream)]
    # Filter out tiny fragments likely from OCR noise
    candidates = [w for w in candidates if len(w) >= 4]

    if not candidates:
        return [], None

    if word_len is None:
        lengths = [len(w) for w in candidates]
        # Fallout usually uses a fixed length; take the mode
        word_len = Counter(lengths).most_common(1)[0][0]

    # Keep only exact-length words; preserve first-seen order and uniqueness
    seen = OrderedDict()
    for w in candidates:
        if len(w) == word_len and w not in seen:
            seen[w] = None
    return list(seen.keys()), word_len


def main():
    ap = argparse.ArgumentParser(description="Extract Fallout terminal hacking words from a screenshot.")
    ap.add_argument("image", help="Path to screenshot image (png/jpg).")
    ap.add_argument("--word-len", type=int, default=None, help="Force a specific word length (otherwise infer).")
    ap.add_argument("--scale", type=int, default=3, help="Upscale factor for OCR (default: 3).")
    ap.add_argument(
        "--debug-ocr",
        action="store_true",
        help="Print raw OCR text to stderr (useful when tuning).",
    )
    ap.add_argument(
        "--debug-stream",
        action="store_true",
        help="Print reconstructed memory stream to stderr (useful when tuning).",
    )
    args = ap.parse_args()

    img = cv2.imread(args.image)
    if img is None:
        print(f"ERROR: Could not read image: {args.image}", file=sys.stderr)
        sys.exit(2)

    pre = preprocess_for_ocr(img, scale=args.scale)
    text = ocr_text(pre)

    if args.debug_ocr:
        print("==== OCR TEXT ====", file=sys.stderr)
        print(text, file=sys.stderr)

    rows = parse_rows(text)
    if not rows:
        print("ERROR: Could not parse any address rows. Try --debug-ocr, or adjust --scale.", file=sys.stderr)
        sys.exit(3)

    colw = infer_column_width(rows)
    stream = reconstruct_stream(rows, colw)

    if args.debug_stream:
        print("==== RECONSTRUCTED STREAM ====", file=sys.stderr)
        print(stream, file=sys.stderr)

    words, inferred_len = extract_words(stream, word_len=args.word_len)

    if not words:
        print("ERROR: No candidate words found. Try --debug-stream or force --word-len.", file=sys.stderr)
        sys.exit(4)

    print(f"# word_length={inferred_len}  column_width={colw}")
    for w in words:
        print(w)


if __name__ == "__main__":
    main()
