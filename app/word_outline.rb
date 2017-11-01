#
#  WordOutline.rb
#  Fallout 3 Hackers Helper
#
#  Created by Morgan Schweers on 3/8/09.
#  Copyright (c) 2009 CyberFOX Software, Inc. All rights reserved.
#

class WordOutline
  class Pair
    attr_reader :key, :value
    def initialize(first, second)
      @key = first
      @value = second
    end

    def children
      return 1 if @value.is_a? String
      @value.length
    end
  end

  def initialize(word_hash)
    @hash = word_hash || {}
    @depth = deep_map(@hash) unless @hash.empty?
  end

  # Possible items...  nil, Pair.new(key, {hash}), Pair.new(key, string)
  def outlineView(_view, numberOfChildrenOfItem: item)
    case item
    when nil then @hash.length
    when Pair then item.children
    else 0
    end
  end

  # If it's not a pair, it's a leaf node.
  def outlineView(_view, isItemExpandable: item)
    item.is_a?(Pair)
  end

  # Return the actual child, not the data that will be used for display.
  # Item can be: nil, Pair.
  def outlineView(_view, child: index, ofItem: item)
    base       = item.nil? ? @hash : item.value
    next_level = item.nil? ? @depth : item.value

    case base
      when String
        base
      else
        key = base.keys.sort[index]
        Pair.new(key, next_level[key])
    end
  end

  # Get the displayable value from the actual child node.
  def outlineView(_view, objectValueForTableColumn: tableColumn, byItem: item)
    item.is_a?(Pair) ? item.key : item
  end

  private

  def deep_map(set)
    {}.tap do |result|
      set.each do |word, hash|
        result[word] = {}
        hash.values.uniq.sort.each do |char_match_count|
          result_set = hash.collect { |x, y| x if y == char_match_count }.compact
          result_set = deep_map(Fallout3Controller.get_result_set(result_set)) if result_set.length > 1
          result_set = result_set.first if result_set.length == 1

          result[word][char_match_count] = result_set
        end
      end
    end
  end
end
