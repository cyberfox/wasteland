#
#  WordOutline.rb
#  Fallout 3 Hackers Helper
#
#  Created by Morgan Schweers on 3/8/09.
#  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
#

class WordOutline
  class Pair
    attr_reader :key, :value
    def initialize(first, second)
      @key = first
      @value = second
    end
  end

  def initialize(words, word_hash)
    @words = words
    @depth = deep_map(word_hash)
    puts @depth.inspect
    @hash = word_hash
    @pair_cache = {}
  end

  # Possible items...  nil, Pair.new(key, {hash}), Pair.new(key, string)
  def outlineView(view, numberOfChildrenOfItem:item)
#    puts "nOCOI: #{item.inspect}"
    return @hash.length if item.nil?
    if item.is_a?(Pair)
      last = item.value
      return 1 if last.is_a?(String)
      return last.length
    end
    return 0
  end

  def outlineView(view, isItemExpandable:item)
    return item.is_a?(Pair)
  end

  # Return the actual child, not the child that will be used for display.
  def outlineView(view, child:index, ofItem:item)
    puts "child: #{index.inspect}, #{item.inspect}"
    @pair_cache[item] = {} if @pair_cache[item].nil?
    @pair_cache[item][index] ||= Pair.new(@hash.keys[index], @depth[@hash.keys[index]]) if item.nil?
    if(item.is_a?(Pair))
      if item.value.is_a?(String)
        @pair_cache[item][index] = item.value
      else
        key = item.value.keys[index]
        @pair_cache[item][index] = Pair.new(key, item.value[key])
      end
    end
    return @pair_cache[item][index]
  end

  def outlineView(view, objectValueForTableColumn:tableColumn, byItem:item)
    puts "oVFTC: #{tableColumn.inspect}, #{item.inspect}, #{item.class}"
    result = item
    puts __LINE__
    result = item.key if item.is_a?(Pair)
    puts __LINE__
    puts "oVFTC returning: #{result.inspect}"
    return result
  end

  def deep_map(set)
    result = {}
    set.each do |word, hash|
      result[word] = {}
      hash.values.uniq.sort.each do |char_match_count|
        result_set = hash.collect {|x, y| x if y == char_match_count}.compact
        result_set = deep_map(Fallout3Controller.get_result_set(result_set)) if(result_set.length > 1)
        result_set = result_set.first if result_set.length == 1

        result[word][char_match_count] = result_set
      end
    end
    result
  end
end
