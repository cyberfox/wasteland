class WordSalad
  attr_reader :depth, :suggestions

  def initialize(words)
    @words = words
    results = get_result_set(@words)

    counts = @words.collect do |word|
      results[word].values.uniq.length
    end

    @suggestions = build_suggestions(counts)
    @depth = deep_map(results)
  end

  def friendly_suggestions
    @suggestions.join(', ')
  end

  def counts(word)
    @depth[word].keys
  end

  def guess(word, similarity)
    @depth[word][similarity]
  end

  def length
    @depth.length
  end

  private

  def get_result_set(words)
    words.inject({}) do |accum, x|
      accum.merge(x => words.inject({}) do |subset, y|
        subset.merge(y => similar(x, y))
      end)
    end.each {|x, y| y.delete(x)}
  end

  def similar(x, y)
    ((0...(x.length)).collect {|index| x[index] == y[index]}).inject(0) {|accum, step| step ? accum+1 : accum}
  end

  def build_suggestions(counts)
    max = counts.max
    @words.select.with_index do |_, index|
      counts[index] == max
    end
  end

  def deep_map(set)
    {}.tap do |result|
      set.each do |word, hash|
        result[word] = {}
        hash.values.uniq.sort.each do |char_match_count|
          initial_result = hash.collect {|x, y| x if y == char_match_count }.compact
          result_set = if initial_result.length > 1
                         WordSalad.new(initial_result)
                       elsif initial_result.length == 1
                         initial_result.first
                       else
                         initial_result
                       end

          result[word][char_match_count] = result_set
        end
      end
    end
  end
end