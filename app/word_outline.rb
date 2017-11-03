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

  def initialize(salad = WordSalad.new([]))
    @salad = salad
  end

  # Possible items...  nil, Pair.new(key, {hash}), Pair.new(key, string)
  def outlineView(_view, numberOfChildrenOfItem: item)
    case item
    when nil then @salad.length
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
    next_level = item.nil? ? @salad : item.value
    next_level = next_level.depth if next_level.respond_to? :depth

    case next_level
      when String
        next_level
      else
        key = next_level.keys.sort[index]
        Pair.new(key, next_level[key])
    end
  end

  # Get the displayable value from the actual child node.
  def outlineView(_view, objectValueForTableColumn: tableColumn, byItem: item)
    item.is_a?(Pair) ? item.key : item
  end
end
