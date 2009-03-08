#
#  Fallout3Controller.rb
#  Fallout 3 Hackers Helper
#
#  Created by Morgan Schweers on 3/7/09.
#  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
#

class Fallout3Controller < NSWindowController
  attr_writer :textentry, :button, :result, :window, :table
  def awakeFromNib
    @textentry.setFont(NSFont.userFixedPitchFontOfSize(NSFont.smallSystemFontSize))
  end

  def analyze(sender)
    @@words, @@result_set = get_words
    counts = @@words.collect do |word|
      @@result_set[word].values.uniq.length
    end
    max = counts.max
    suggestions = []
    @@words.each_with_index do |word,index|
      suggestions << word if counts[index] == max
    end
    outline = WordOutline.new(@@words, @@result_set)
    @result.stringValue = suggestions.join(', ')
    @table.dataSource = outline
  end

  def select(sender)
    words, result_set = get_words
    editor = @window.fieldEditor(true, forObject:@result)
    selection = editor.selectedRange
    substring = editor.attributedSubstringFromRange(selection)
    puts editor.inspect
    puts selection.inspect
    puts substring.inspect
    puts substring.string
    @result.stringValue = result_set[substring.string].inspect
  end

  def get_words
    words = @textentry.textStorage.string.split("\n")
    result_set = Fallout3Controller.get_result_set(words)
    [words, result_set]
  end

  def self.get_result_set(words)
    result = words.inject({}) {|accum, x| accum.merge(x => words.inject({}) {|subset, y| subset.merge(y => similar(x,y))})}
    result.each {|x, y| y.delete(x)}
    result
  end

  def self.similar(x,y)
    ((0...(x.length)).collect {|index| x[index] == y[index]}).inject(0) {|accum, step| step ? accum+1 : accum}
  end
end

#1234
#4321
#1245
#2143
#5432
#3412
