#
#  WordOutline.rb
#  Fallout 3 Hackers Helper
#
#  Created by Morgan Schweers on 3/8/09.
#  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
#

class WordOutline
  def initialize(words, word_hash)
    @words = words
    @depth = deep_map(word_hash)
    puts @depth.inspect
    @hash = word_hash
  end

  # Possible items...  nil, [key, {hash}], [key, string]
  def outlineView(view, numberOfChildrenOfItem:item)
    puts "nOCOI: #{item.inspect}"
    return @hash.length if item.nil?
    return (item.last.is_a?(String) ? 1 : item.last.length) if item.is_a?(Array)
    return 0
  end

  def outlineView(view, isItemExpandable:item)
    return !item.is_a?(String)
  end

  # Return the actual child, not the child that will be used for display.
  def outlineView(view, child:index, ofItem:item)
    puts "child: #{index.inspect}, #{item.inspect}"
    return [@hash.keys[index], @depth[@hash.keys[index]]] if item.nil?
    if(item.is_a?(Array))
      return item.last if item.last.is_a?(String)
      key = item.last.keys[index]
      return [key, item.last[key]]
    end
    return nil
  end

  def outlineView(view, objectValueForTableColumn:tableColumn, byItem:item)
    puts "oVFTC: #{tableColumn.inspect}, #{item.inspect}, #{item.class}"
    item = item.first if !item.is_a?(String) && item.respond_to?(:first) && item.length > 0
    result = item.to_s
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
