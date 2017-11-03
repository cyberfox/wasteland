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
    @empty_outline = WordOutline.new
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
    ws = WordSalad.new(words)
    @outline = WordOutline.new(ws)
    @table.dataSource = @outline
    @result.stringValue = ws.friendly_suggestions
  end

  private
  def words
    @textentry.textStorage.string.split.map(&:downcase)
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
