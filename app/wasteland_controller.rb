#
#  wasteland_controller.rb
#  Fallout 3 Hackers Helper
#
#  Created by Morgan Schweers on 3/7/09.
#  Copyright (c) 2009 CyberFOX Software, Inc. All rights reserved.
#

class Fallout3Controller < NSWindowController
  extend IB
  outlet :textentry, NSTextView
  outlet :result, NSTextField
  outlet :window, NSWindow
  outlet :table, NSOutlineView

  def awakeFromNib
    @textentry.setFont(NSFont.userFixedPitchFontOfSize(NSFont.smallSystemFontSize))
    @empty_string = ''.attrd
    @empty_outline = WordOutline.new(nil)
    @sample_data = SAMPLE_DATA.attrd
  end

  def clear(sender)
    @textentry.textStorage.setAttributedString(@empty_string)
    @table.dataSource=@empty_outline
    @table.reloadData
    @result.stringValue=''
  end

  def sample_data(sender)
    clear(sender)
    @textentry.textStorage.setAttributedString(@sample_data)
    @textentry.setFont(NSFont.userFixedPitchFontOfSize(NSFont.smallSystemFontSize))
  end

  def analyze(sender)
    @words, @result_set = get_words
    counts = @words.collect do |word|
      @result_set[word].values.uniq.length
    end
    max = counts.max
    suggestions = []
    @words.each_with_index do |word,index|
      suggestions << word if counts[index] == max
    end
    @outline = WordOutline.new(@result_set)
    @table.dataSource = @outline
    @result.stringValue = suggestions.join(', ')
  end

  def self.get_result_set(words)
    result = words.inject({}) {|accum, x| accum.merge(x => words.inject({}) {|subset, y| subset.merge(y => similar(x,y))})}
    result.each {|x, y| y.delete(x)}
    result
  end

  private
  def get_words
    words = @textentry.textStorage.string.split("\n")
    result_set = Fallout3Controller.get_result_set(words)
    [words, result_set]
  end

  def self.similar(x,y)
    ((0...(x.length)).collect {|index| x[index] == y[index]}).inject(0) {|accum, step| step ? accum+1 : accum}
  end

  def select(sender)
    words, result_set = get_words
    editor = @window.fieldEditor(true, forObject:@result)
    selection = editor.selectedRange
    substring = editor.attributedSubstringFromRange(selection)
    @result.stringValue = result_set[substring.string].inspect
  end

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
end
