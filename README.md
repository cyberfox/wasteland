# Wasteland

A hacker's helper for the terminal hacking minigame in Fallout 3, Fallout: New Vegas, and Fallout 4.

Given a list of candidate words from the terminal screen, Wasteland analyzes character similarities between words and suggests the most likely password by counting matching letter positions — the same logic the game uses internally.

## How it works

The game's hacking mechanic is essentially a word-guessing game where each guess tells you how many letters match the password at the same position. Wasteland pre-computes all pairwise similarities so you can make optimal guesses and narrow down candidates quickly.

## Original app (MacRuby/macOS)

The `app/` directory contains the original MacRuby macOS application built in 2009:

- **word_salad.rb** — Core solver engine. Takes a word list, computes pairwise character matches, and suggests optimal guesses.
- **wasteland_controller.rb** — macOS GUI controller (Interface Builder outlets).
- **word_outline.rb** — NSOutlineView data source for displaying word relationships.

Requires MacRuby and Interface Builder (`ib` gem). Not actively maintained.

## OCR Solver (`ocr-solver/`)

A modern Python-based approach that solves the hacking minigame directly from screenshots:

1. Screenshots the terminal
2. OCRs with Tesseract via OpenCV
3. Parses OCR-mangled hex addresses and candidate words
4. Reconstructs the memory stream
5. Solves for the correct password

See [`ocr-solver/README.md`](ocr-solver/README.md) for setup and usage.

## Usage (CLI)

```ruby
require './app/word_salad'

words = %w[settling sentence sundries pristine sinister constant sneaking ambition scouting starting shooting junktown contains subjects trusting lunatics jonathan]

salad = WordSalad.new(words)
puts "Suggestions: #{salad.friendly_suggestions}"
puts "Depth: #{salad.length} words remaining"
```

## License

MIT
