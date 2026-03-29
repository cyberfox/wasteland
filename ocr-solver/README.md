# OCR Solver for Fallout Terminal Hacking

Automatically solves the Fallout terminal hacking minigame from screenshots.

## How it works
1. Takes a screenshot of the hacking terminal
2. OCRs the screen with Tesseract via OpenCV
3. Parses OCR-mangled address tokens (handles hex confusions)
4. Reconstructs memory stream in address order
5. Extracts candidate password words
6. Solves for the correct password

## Requirements
```
pip install opencv-python pytesseract
brew install tesseract  # macOS
```

## Usage
```
python fall_out_hack_parse_better_2.py screenshot.png
```
