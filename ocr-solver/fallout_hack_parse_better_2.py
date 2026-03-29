#!/usr/bin/env python3
"""
Fallout terminal hacking screen parser.

- OCRs the screenshot
- Parses OCR-mangled address tokens (0x / Ox / @x and hex digit confusions)
- Reconstructs the memory stream in address order
- Extracts candidate password words (fixed length) robustly even when OCR introduces digits

Requirements:
  pip install opencv-python pytesseract
  + system tesseract installed (brew install tesseract)
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

    # Contrast enhancement (works well on green glow + scanlines)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    gray = clahe.apply(gray)

    # Light blur to reduce scanline noise
    gray = cv2.GaussianBlur(gray, (3, 3), 0)

    _, th = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    # Cleanup
    kernel = np.ones((2, 2), np.uint8)
    th = cv2.morphologyEx(th, cv2.MORPH_OPEN, kernel, iterations=1)
    th = cv2.morphologyEx(th, cv2.MORPH_CLOSE, kernel, iterations=1)

    return th


def ocr_text(img_bin: np.ndarray, psm: int = 4) -> str:
    # IMPORTANT: no literal double-quote in whitelist (breaks shlex)
    whitelist = (
        "0123456789abcdefABCDEFxX"
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "[]{}()<>"
        "!@#$%^&*-_=+;:'.,?/\\|`~"
    )
    config = f'--oem 3 --psm {psm} -c tessedit_char_whitelist="{whitelist}"'
    return pytesseract.image_to_string(img_bin, config=config)


# -----------------------------
# Parsing & reconstruction
# -----------------------------

def parse_segments(ocr: str):
    """
    Extract (address, data) segments from OCR text.
    For each line, grab each address token, and the text after it up to the next address token.
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
    candidates = [x for x in lengths if 8 <= x <= 24] or lengths
    return Counter(candidates).most_common(1)[0][0]


def reconstruct_stream(segments, col_width: int) -> str:
    parts = []
    for _addr, data in sorted(segments, key=lambda t: t[0]):
        parts.append(data[:col_width].ljust(col_width, "?"))
    return "".join(parts)


# -----------------------------
# Word extraction (tolerant)
# -----------------------------

# Capture alphanumeric runs, because OCR often mixes digits into the words.
ALNUM_RUN_RE = re.compile(r"[A-Z0-9]{4,}")

# Map common OCR digit confusions back to letters.
# The key one for Fallout terminals is often 9 ≈ T.
OCR_CHAR_MAP = str.maketrans({
    "0": "O",
    "1": "I",
    "2": "Z",
    "3": "E",
    "4": "A",
    "5": "S",
    "6": "G",
    "7": "T",
    "8": "B",
    "9": "T",
})

def normalize_candidate(token: str) -> str:
    return token.translate(OCR_CHAR_MAP)

def infer_word_len_from_tokens(tokens) -> int | None:
    if not tokens:
        return None
    lengths = [len(t) for t in tokens if len(t) >= 4]
    if not lengths:
        return None
    # Fallout screen typically has a fixed length; mode is usually correct.
    return Counter(lengths).most_common(1)[0][0]

def extract_words(stream: str, word_len: int | None):
    runs = [m.group(0) for m in ALNUM_RUN_RE.finditer(stream)]
    if not runs:
        return [], None

    # Normalize runs (digits -> likely letters)
    norm_runs = [normalize_candidate(r) for r in runs]

    if word_len is None:
        word_len = infer_word_len_from_tokens(norm_runs)

    if not word_len or word_len < 4:
        return [], None

    seen = OrderedDict()

    # Keep exact-length tokens
    for t in norm_runs:
        if len(t) == word_len and t.isalpha():
            seen.setdefault(t, None)

    # ALSO: Some OCR runs may be longer (e.g., an extra char stuck on).
    # Take sliding windows of length word_len from longer runs, but only if purely letters.
    for t in norm_runs:
        if len(t) > word_len:
            for i in range(0, len(t) - word_len + 1):
                w = t[i:i + word_len]
                if w.isalpha():
                    seen.setdefault(w, None)

    return list(seen.keys()), word_len


# -----------------------------
# Main
# -----------------------------

def main():
    ap = argparse.ArgumentParser(description="Parse Fallout hacking terminal screenshots.")
    ap.add_argument("image", help="Path to screenshot image")
    ap.add_argument("--word-len", type=int, default=None, help="Force word length (e.g. 7)")
    ap.add_argument("--scale", type=int, default=3, help="OCR upscale factor (default 3)")
    ap.add_argument("--psm", type=int, default=4, help="Tesseract PSM (default 4; try 6 or 11)")
    ap.add_argument("--debug-ocr", action="store_true")
    ap.add_argument("--debug-stream", action="store_true")
    args = ap.parse_args()

    img = cv2.imread(args.image)
    if img is None:
        print(f"ERROR: Could not read image: {args.image}", file=sys.stderr)
        sys.exit(2)

    pre = preprocess_for_ocr(img, scale=args.scale)
    text = ocr_text(pre, psm=args.psm)

    if args.debug_ocr:
        print("==== OCR TEXT ====", file=sys.stderr)
        print(text, file=sys.stderr)

    segments = parse_segments(text)
    if not segments:
        print("ERROR: No address segments parsed. Try --debug-ocr, --psm 6, or --scale 4.", file=sys.stderr)
        sys.exit(3)

    colw = infer_column_width(segments)
    stream = reconstruct_stream(segments, colw)

    if args.debug_stream:
        print("==== STREAM ====", file=sys.stderr)
        print(stream, file=sys.stderr)

    words, wl = extract_words(stream, args.word_len)
    if not words:
        print("ERROR: No candidate words found. Try --word-len 7 or --psm 6.", file=sys.stderr)
        sys.exit(4)

    print(f"# word_length={wl} column_width={colw}")
    for w in words:
        print(w)


if __name__ == "__main__":
    main()