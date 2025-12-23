const API_BASE = 'http://localhost:4567';

export interface GameState {
  game_id: string;
  suggestion: string;
  remaining_words: number;
  history: { guess: string; match_count: number }[];
  solved?: boolean;
  word?: string;
}

export interface AnalyzeResult {
  words: string[];
  suggestion: string;
  remaining_words: number;
}

export const api = {
  // Start a new game
  async newGame(words: string[]): Promise<GameState> {
    const response = await fetch(`${API_BASE}/game/new`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ words }),
    });
    if (!response.ok) throw new Error('Failed to create game');
    return response.json();
  },

  // Submit a guess
  async guess(gameId: string, guess: string, matchCount: number): Promise<GameState> {
    const response = await fetch(`${API_BASE}/game/${gameId}/guess`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ guess, match_count: matchCount }),
    });
    if (!response.ok) throw new Error('Failed to submit guess');
    return response.json();
  },

  // Get game state
  async getGameState(gameId: string): Promise<GameState> {
    const response = await fetch(`${API_BASE}/game/${gameId}`);
    if (!response.ok) throw new Error('Failed to get game state');
    return response.json();
  },

  // Analyze text to extract words and get suggestion
  async analyzeText(text: string): Promise<AnalyzeResult> {
    const response = await fetch(`${API_BASE}/analyze/text`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text }),
    });
    if (!response.ok) throw new Error('Failed to analyze text');
    return response.json();
  },
};
