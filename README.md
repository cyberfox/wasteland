# Word Salad - Web App

A Mastermind-style word guessing game where you try to guess a secret word by iteratively providing feedback on how many letters match the suggested word.

## Tech Stack

### Backend
- **Ruby** with Sinatra web framework
- **Puma** web server
- Existing `WordSalad` game logic class

### Frontend
- **React** with TypeScript
- **Vite** for build tooling
- **Tailwind CSS** for styling

## Features

- Extract word lists from text (paste from game board)
- Get intelligent word suggestions based on remaining possibilities
- Interactive guessing interface with match count selection
- Guess history tracking
- Real-time feedback on remaining possibilities
- Win detection with solution display

## Setup

### Prerequisites
- Ruby 3.x
- Node.js 18+
- Bundler

### Backend Setup

```bash
# Install Ruby dependencies
bundle install

# Start the backend server
bundle exec ruby server.rb -p 4567
```

The backend will run on `http://localhost:4567`.

### Frontend Setup

```bash
cd frontend

# Install Node dependencies
npm install

# Start the development server
npm run dev
```

The frontend will run on `http://localhost:5173`.

## API Documentation

### Start a New Game
```
POST /game/new
Content-Type: application/json

{
  "words": ["settling", "sentence", "sundries", "pristine", "sinister"]
}

Response:
{
  "game_id": "30e31c00-51ae-4824-afaa-ebcd33d44991",
  "suggestion": "sinister",
  "remaining_words": 5,
  "history": []
}
```

### Submit a Guess
```
POST /game/:id/guess
Content-Type: application/json

{
  "guess": "sinister",
  "match_count": 3
}

Response (solved):
{
  "solved": true,
  "word": "sundries",
  "history": [{"guess": "sinister", "match_count": 3}]
}

Response (continue):
{
  "solved": false,
  "suggestion": "settling",
  "remaining_words": 3,
  "history": [{"guess": "sinister", "match_count": 3}]
}
```

### Get Game State
```
GET /game/:id

Response:
{
  "game_id": "30e31c00-51ae-4824-afaa-ebcd33d44991",
  "suggestion": "sinister",
  "remaining_words": 5,
  "history": []
}
```

### Analyze Text (Extract Words)
```
POST /analyze/text
Content-Type: application/json

{
  "text": "settling sentence sundries pristine sinister"
}

Response:
{
  "words": ["settling", "sentence", "sundries", "pristine", "sinister"],
  "suggestion": "sinister",
  "remaining_words": 5
}
```

### Health Check
```
GET /health

Response:
{
  "status": "ok"
}
```

## Frontend Components

### ImageUpload
- Text area for pasting word lists
- Analyzes text and extracts words
- Returns best first suggestion
- Ready for OCR integration (image upload)

### GameBoard
- Displays current suggested word
- Shows remaining possible words
- Input field for user's guess
- Match count selector (0 to word length)
- Guess history display
- Win/solved state with solution

## How to Play

1. **Extract Words**: Paste the word list from your game board into the text area and click "Analyze & Get Suggestion"
2. **Get Suggestion**: The app will suggest the best word to try first
3. **Make Guess**: Enter your guess and select how many letters match the suggested word
4. **Iterate**: The app will narrow down the possibilities and suggest the next best word
5. **Solve**: Continue until the app identifies the correct word

## Future Work

### OCR Integration
The app is designed to support image upload with OCR for automatic word extraction from game board photos. To add this:

1. Add OCR endpoint in `server.rb`:
```ruby
post '/analyze/image' do
  # Handle image upload
  # Call OCR service
  # Extract and return words
end
```

2. Update `ImageUpload.tsx` to handle file upload
3. Integrate your chosen OCR technology

### Sub-path Hosting
To host on a sub-path (e.g., `example.com/wasteland`):

1. Configure Vite base path in `vite.config.ts`:
```typescript
export default defineConfig({
  base: '/wasteland/',
  // ...
})
```

2. Update API base URL in `frontend/src/api.ts`:
```typescript
const API_BASE = 'https://example.com/wasteland/api';
```

3. Configure reverse proxy (nginx, Apache, etc.) to route `/wasteland/api` to the Sinatra backend

## Development

### Backend
```bash
# Run with auto-reload (requires shotgun gem)
bundle exec shotgun -p 4567

# Or standard server
bundle exec ruby server.rb -p 4567
```

### Frontend
```bash
cd frontend
npm run dev    # Development server
npm run build  # Production build
npm run preview  # Preview production build
```

## Project Structure

```
wasteland/
├── app/
│   ├── word_salad.rb      # Core game logic
│   └── ...
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── ImageUpload.tsx
│   │   │   └── GameBoard.tsx
│   │   ├── api.ts         # API client
│   │   ├── App.tsx        # Main app
│   │   └── ...
│   ├── package.json
│   └── ...
├── server.rb              # Sinatra backend
├── Gemfile
└── README.md
```

## License

Original codebase converted from iOS/macOS RubyMotion app.
