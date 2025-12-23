import { useState } from 'react';
import { api } from '../api';

interface GameBoardProps {
  gameId: string;
  initialSuggestion: string;
  initialRemaining: number;
  initialHistory: { guess: string; match_count: number }[];
  onReset: () => void;
}

export default function GameBoard({
  gameId,
  initialSuggestion,
  initialRemaining,
  initialHistory,
  onReset,
}: GameBoardProps) {
  const [suggestion, setSuggestion] = useState(initialSuggestion);
  const [remainingWords, setRemainingWords] = useState(initialRemaining);
  const [history, setHistory] = useState(initialHistory);
  const [guess, setGuess] = useState('');
  const [matchCount, setMatchCount] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [solved, setSolved] = useState(false);
  const [solution, setSolution] = useState('');

  const handleSubmitGuess = async () => {
    if (!guess.trim()) {
      setError('Please enter a guess');
      return;
    }
    if (matchCount === null) {
      setError('Please select the number of matching letters');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const result = await api.guess(gameId, guess, matchCount);

      if (result.solved) {
        setSolved(true);
        setSolution(result.word!);
      } else {
        setSuggestion(result.suggestion);
        setRemainingWords(result.remaining_words);
        setHistory(result.history);
        setGuess('');
        setMatchCount(null);
      }
    } catch (err) {
      setError('Failed to submit guess. Please try again.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  if (solved) {
    return (
      <div className="bg-white rounded-lg shadow-md p-6 max-w-2xl mx-auto">
        <div className="text-center">
          <h2 className="text-3xl font-bold text-green-600 mb-4">🎉 Solved!</h2>
          <p className="text-xl mb-6">The word is:</p>
          <div className="text-4xl font-bold text-gray-800 mb-6">{solution}</div>
          <div className="bg-gray-100 rounded-lg p-4 mb-6">
            <h3 className="font-semibold mb-2">Guess History:</h3>
            <ul className="space-y-1">
              {history.map((h, i) => (
                <li key={i} className="text-sm">
                  {h.guess} → {h.match_count} matches
                </li>
              ))}
            </ul>
          </div>
          <button
            onClick={onReset}
            className="bg-blue-600 text-white py-2 px-6 rounded-md hover:bg-blue-700 transition-colors"
          >
            Start New Game
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-md p-6 max-w-2xl mx-auto">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-gray-800">Game in Progress</h2>
        <button
          onClick={onReset}
          className="text-sm text-gray-600 hover:text-gray-800 underline"
        >
          Start Over
        </button>
      </div>

      <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
        <p className="text-sm text-blue-800 mb-1">Suggested word:</p>
        <p className="text-2xl font-bold text-blue-900">{suggestion}</p>
        <p className="text-sm text-blue-700 mt-2">
          {remainingWords} possible word{remainingWords !== 1 ? 's' : ''} remaining
        </p>
      </div>

      <div className="space-y-4 mb-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Your guess
          </label>
          <input
            type="text"
            value={guess}
            onChange={(e) => setGuess(e.target.value)}
            placeholder="Enter your guess..."
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            How many letters match the suggestion?
          </label>
          <div className="flex gap-2 flex-wrap">
            {Array.from({ length: suggestion.length + 1 }, (_, i) => (
              <button
                key={i}
                onClick={() => setMatchCount(i)}
                className={`w-12 h-12 rounded-md font-bold transition-colors ${
                  matchCount === i
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-200 text-gray-800 hover:bg-gray-300'
                }`}
              >
                {i}
              </button>
            ))}
          </div>
        </div>
      </div>

      {error && (
        <div className="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
          {error}
        </div>
      )}

      <button
        onClick={handleSubmitGuess}
        disabled={loading}
        className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors"
      >
        {loading ? 'Processing...' : 'Submit Guess'}
      </button>

      {history.length > 0 && (
        <div className="mt-6 border-t pt-4">
          <h3 className="font-semibold text-gray-700 mb-2">Guess History:</h3>
          <ul className="space-y-1">
            {history.map((h, i) => (
              <li key={i} className="text-sm text-gray-600">
                {h.guess} → {h.match_count} matches
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
