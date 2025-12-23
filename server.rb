require 'sinatra'
require 'sinatra/json'
require 'json'
require 'securerandom'
require './app/word_salad'

# Enable CORS for frontend
before do
  content_type :json
  headers['Access-Control-Allow-Origin'] = '*'
  headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
  headers['Access-Control-Allow-Headers'] = 'Content-Type'
end

options '*' do
  response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
  response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
  200
end

# Store game sessions in memory
games = {}

# Helper to serialize WordSalad for JSON
def serialize_word_salad(ws)
  {
    suggestion: ws.friendly_suggestions,
    remaining_words: ws.length
  }
end

# Start a new game
post '/game/new' do
  data = JSON.parse(request.body.read)
  words = data['words']

  if words.nil? || words.empty?
    status 400
    return json({ error: 'words array is required' })
  end

  game_id = SecureRandom.uuid
  games[game_id] = {
    words: words,
    word_salad: WordSalad.new(words),
    history: []
  }

  game_state = games[game_id]
  suggestion = game_state[:word_salad].suggestions.first
  json({
    game_id: game_id,
    suggestion: suggestion,
    remaining_words: words.length,
    possible_matches: game_state[:word_salad].counts(suggestion),
    history: []
  })
end

# Submit a guess
post '/game/:id/guess' do
  game_id = params[:id]
  data = JSON.parse(request.body.read)
  guess = data['guess']
  match_count = data['match_count']

  game = games[game_id]
  if game.nil?
    status 404
    return json({ error: 'Game not found' })
  end

  if guess.nil? || match_count.nil?
    status 400
    return json({ error: 'guess and match_count are required' })
  end

  result = game[:word_salad].guess(guess, match_count)

  # Record history
  game[:history] << {
    guess: guess,
    match_count: match_count
  }

  if result.is_a?(String)
    # Game solved
    json({
      solved: true,
      word: result,
      history: game[:history]
    })
  else
    # Continue game
    game[:word_salad] = result
    suggestion = result.suggestions.first
    json({
      solved: false,
      suggestion: suggestion,
      remaining_words: result.length,
      possible_matches: result.counts(suggestion),
      history: game[:history]
    })
  end
end

# Get game state
get '/game/:id' do
  game_id = params[:id]
  game = games[game_id]

  if game.nil?
    status 404
    return json({ error: 'Game not found' })
  end

  suggestion = game[:word_salad].suggestions.first
  json({
    game_id: game_id,
    suggestion: suggestion,
    remaining_words: game[:word_salad].length,
    possible_matches: game[:word_salad].counts(suggestion),
    history: game[:history]
  })
end

# Analyze text to extract words and get best suggestion
post '/analyze/text' do
  data = JSON.parse(request.body.read)
  text = data['text']

  if text.nil? || text.empty?
    status 400
    return json({ error: 'text is required' })
  end

  # Extract words (split by whitespace, filter out empty strings)
  words = text.split(/\s+/).map(&:strip).select { |w| !w.empty? }

  if words.empty?
    status 400
    return json({ error: 'No words found in text' })
  end

  # Get best suggestion
  word_salad = WordSalad.new(words)

  json({
    words: words,
    suggestion: word_salad.friendly_suggestions,
    remaining_words: words.length
  })
end

# Health check
get '/health' do
  json({ status: 'ok' })
end
