import { useState } from 'react';
import { api } from '../api';
import type { AnalyzeResult } from '../api';

interface ImageUploadProps {
  onAnalyzeComplete: (result: AnalyzeResult) => void;
}

export default function ImageUpload({ onAnalyzeComplete }: ImageUploadProps) {
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleAnalyze = async () => {
    if (!text.trim()) {
      setError('Please enter some text');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const result = await api.analyzeText(text);
      onAnalyzeComplete(result);
    } catch (err) {
      setError('Failed to analyze text. Please try again.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white rounded-lg shadow-md p-6 max-w-2xl mx-auto">
      <h2 className="text-2xl font-bold mb-4 text-gray-800">Extract Words from Game Board</h2>

      <div className="mb-4">
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Paste the word list from your game board
        </label>
        <textarea
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Paste words here (one per line or separated by spaces)..."
          className="w-full h-48 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      {error && (
        <div className="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
          {error}
        </div>
      )}

      <button
        onClick={handleAnalyze}
        disabled={loading}
        className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors"
      >
        {loading ? 'Analyzing...' : 'Analyze & Get Suggestion'}
      </button>

      <p className="mt-4 text-sm text-gray-600">
        Note: Image upload with OCR will be added once the OCR technology is provided.
      </p>
    </div>
  );
}
