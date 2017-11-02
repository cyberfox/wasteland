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
    @outline = WordOutline.new(@result_set, deep_map(@result_set))
    @table.dataSource = @outline
    @result.stringValue = suggestions.join(', ')
  end

  def get_result_set(words)
    words.inject({}) do |accum, x|
      accum.merge(x => words.inject({}) do |subset, y|
        subset.merge(y => similar(x, y))
      end)
    end.each {|x, y| y.delete(x)}
  end

  private
  def get_words
    words = @textentry.textStorage.string.split.map(&:downcase)
    result_set = get_result_set(words)
    [words, result_set]
  end

  def similar(x, y)
    ((0...(x.length)).collect {|index| x[index] == y[index]}).inject(0) {|accum, step| step ? accum+1 : accum}
  end

  def select(sender)
    words, result_set = get_words
    editor = @window.fieldEditor(true, forObject:@result)
    selection = editor.selectedRange
    substring = editor.attributedSubstringFromRange(selection)
    @result.stringValue = result_set[substring.string].inspect
  end

  private
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
