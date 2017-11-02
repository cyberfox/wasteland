class WordSalad
  attr_accessor :depth, :results

  def initialize(words)
    @words = words
    @results = get_result_set(@words)

    counts = @words.collect do |word|
      @results[word].values.uniq.length
    end

    @suggestions = build_suggestions(counts)
    @depth = deep_map(@results)
  end

  def suggestions
    @suggestions.join(', ')
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
          result_set = hash.collect {|x, y| x if y == char_match_count }.compact
          result_set = deep_map(get_result_set(result_set)) if result_set.length > 1
          result_set = result_set.first if result_set.length == 1

          result[word][char_match_count] = result_set
        end
      end
    end
  end
end