#!/usr/bin/env python3
"""
Fallout terminal hacking screen parser.

Given a screenshot of a Fallout hacking terminal, this script:
- OCRs the screen
- Detects and normalizes OCR-mangled address tokens (0xFxxx)
- Reconstructs the underlying memory stream in address order
- Extracts candidate password words of fixed length

Tested against real Fallout screenshots with messy OCR.
"""

import argparse
import re
import sys
from collections import Counter, OrderedDict

import cv2
import numpy as np
import pytesseract


# -----------------------------
# Address token handling
# -----------------------------

# OCR often turns:
#   0x -> Ox / @x
#   5  -> S
#   8  -> B
#   1  -> I / l
ADDR_TOKEN_RE = re.compile(
    r"(?P<prefix>[0O@])x(?P<hex>[0-9A-Fa-fOSBIZGl]{4})"
)

def normalize_hex4(hex4: str) -> str:
    x = hex4.upper()
    return (
        x.replace("O", "0")
         .replace("I", "1")
         .replace("L", "1")
         .replace("S", "5")
         .replace("B", "8")
         .replace("Z", "2")
         .replace("G", "6")
    )

def parse_addr(match: re.Match) -> int | None:
    try:
        return int(normalize_hex4(match.group("hex")), 16)
    except ValueError:
        return None


# -----------------------------
# OCR preprocessing
# -----------------------------

def preprocess_for_ocr(bgr: np.ndarray, scale: int = 3) -> np.ndarray:
    h, w = bgr.shape[:2]
    bgr = cv2.resize(bgr, (w * scale, h * scale), interpolation=cv2.INTER_CUBIC)

    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)

    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    gray = clahe.apply(gray)

    gray = cv2.GaussianBlur(gray, (3, 3), 0)

    _, th = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    kernel = np.ones((2, 2), np.uint8)
    th = cv2.morphologyEx(th, cv2.MORPH_OPEN, kernel, iterations=1)
    th = cv2.morphologyEx(th, cv2.MORPH_CLOSE, kernel, iterations=1)

    return th


def ocr_text(img_bin: np.ndarray) -> str:
    # IMPORTANT: no literal double-quote in whitelist (breaks shlex)
    whitelist = (
        "0123456789abcdefABCDEFxX"
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "[]{}()<>"
        "!@#$%^&*-_=+;:'.,?/\\|`~"
    )
    config = f'--oem 3 --psm 6 -c tessedit_char_whitelist="{whitelist}"'
    return pytesseract.image_to_string(img_bin, config=config)


# -----------------------------
# Parsing & reconstruction
# -----------------------------

def parse_segments(ocr: str):
    """
    Extract (address, data) segments from OCR text.
    """
    segments = []

    for raw_line in ocr.splitlines():
        line = raw_line.strip()
        if not line:
            continue

        matches = list(ADDR_TOKEN_RE.finditer(line))
        if not matches:
            continue

        for i, m in enumerate(matches):
            addr = parse_addr(m)
            if addr is None:
                continue

            start = m.end()
            end = matches[i + 1].start() if i + 1 < len(matches) else len(line)
            data = re.sub(r"\s+", "", line[start:end])
            segments.append((addr, data))

    return segments


def infer_column_width(segments) -> int:
    lengths = [len(data) for _addr, data in segments if data]
    if not lengths:
        return 12

    candidates = [x for x in lengths if 6 <= x <= 24] or lengths
    return Counter(candidates).most_common(1)[0][0]


def reconstruct_stream(segments, col_width: int) -> str:
    parts = []
    for _addr, data in sorted(segments, key=lambda t: t[0]):
        parts.append(data[:col_width].ljust(col_width, "?"))
    return "".join(parts)


# -----------------------------
# Word extraction
# -----------------------------

UPWORD_RE = re.compile(r"[A-Z]+")

def extract_words(stream: str, word_len: int | None):
    words = [m.group(0) for m in UPWORD_RE.finditer(stream)]
    words = [w for w in words if len(w) >= 4]

    if not words:
        return [], None

    if word_len is None:
        word_len = Counter(len(w) for w in words).most_common(1)[0][0]

    seen = OrderedDict()
    for w in words:
        if len(w) == word_len:
            seen.setdefault(w, None)

    return list(seen.keys()), word_len


# -----------------------------
# Main
# -----------------------------

def main():
    ap = argparse.ArgumentParser(description="Parse Fallout hacking terminal screenshots.")
    ap.add_argument("image", help="Path to screenshot image")
    ap.add_argument("--word-len", type=int, default=None, help="Force word length")
    ap.add_argument("--scale", type=int, default=3, help="OCR upscale factor")
    ap.add_argument("--debug-ocr", action="store_true")
    ap.add_argument("--debug-stream", action="store_true")
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

    segments = parse_segments(text)
    if not segments:
        print("ERROR: No address segments parsed.", file=sys.stderr)
        sys.exit(3)

    colw = infer_column_width(segments)
    stream = reconstruct_stream(segments, colw)

    if args.debug_stream:
        print("==== STREAM ====", file=sys.stderr)
        print(stream, file=sys.stderr)

    words, wl = extract_words(stream, args.word_len)
    if not words:
        print("ERROR: No candidate words found.", file=sys.stderr)
        sys.exit(4)

    print(f"# word_length={wl} column_width={colw}")
    for w in words:
        print(w)


if __name__ == "__main__":
    main()
