require './app/word_salad'
  SAMPLE_DATA = <<EOSAMPLE
settling
sentence
sundries
pristine
sinister
constant
sneaking
ambition
scouting
starting
shooting
junktown
contains
subjects
trusting
lunatics
jonathan
EOSAMPLE
ws = WordSalad.new(SAMPLE_DATA.split)
while true
  puts "I suggest: #{ws.friendly_suggestions}"
  guess = gets.strip
  puts "Is the number of matching letters: #{ws.counts(guess).join(', ')}"
  count = gets.strip.to_i
  result = ws.guess(guess, count)
  if result.is_a? String
    puts "The word is: #{result}"
    exit
  end
  ws = result
end
