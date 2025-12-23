import { useState } from 'react';
import ImageUpload from './components/ImageUpload';
import GameBoard from './components/GameBoard';
import { api } from './api';
import type { AnalyzeResult } from './api';

type AppState = 'upload' | 'playing';

function App() {
  const [appState, setAppState] = useState<AppState>('upload');
  const [gameId, setGameId] = useState('');
  const [suggestion, setSuggestion] = useState('');
  const [remainingWords, setRemainingWords] = useState(0);
  const [possibleMatches, setPossibleMatches] = useState<number[]>([]);
  const [history, setHistory] = useState<{ guess: string; match_count: number }[]>([]);

  const handleAnalyzeComplete = async (result: AnalyzeResult) => {
    try {
      const gameState = await api.newGame(result.words);
      setGameId(gameState.game_id);
      setSuggestion(gameState.suggestion);
      setRemainingWords(gameState.remaining_words);
      setPossibleMatches(gameState.possible_matches);
      setHistory(gameState.history);
      setAppState('playing');
    } catch (err) {
      console.error('Failed to start game:', err);
      alert('Failed to start game. Please try again.');
    }
  };

  const handleReset = () => {
    setGameId('');
    setSuggestion('');
    setRemainingWords(0);
    setPossibleMatches([]);
    setHistory([]);
    setAppState('upload');
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 py-12 px-4">
      <div className="max-w-4xl mx-auto">
        <header className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-800 mb-2">Word Salad</h1>
          <p className="text-gray-600">Mastermind-style word guessing game</p>
        </header>

        {appState === 'upload' && (
          <ImageUpload onAnalyzeComplete={handleAnalyzeComplete} />
        )}

        {appState === 'playing' && (
          <GameBoard
            gameId={gameId}
            initialSuggestion={suggestion}
            initialRemaining={remainingWords}
            initialPossibleMatches={possibleMatches}
            initialHistory={history}
            onReset={handleReset}
          />
        )}
      </div>
    </div>
  );
}

export default App;
