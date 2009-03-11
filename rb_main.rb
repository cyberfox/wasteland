#
# rb_main.rb
# Fallout 3 Hackers Helper
#
# Created by Morgan Schweers on 3/7/09.
# Copyright (c) CyberFOX Software, Inc., 2009. All rights reserved.
#

# Loading the Cocoa framework. If you need to load more frameworks, you can
# do that here too.
framework 'Cocoa'

$LOAD_PATH.unshift File.join(NSBundle.mainBundle.privateFrameworksPath, 'MacRuby.framework/Versions/Current/usr/lib/ruby/1.9.1') 

# Loading all the Ruby project files.
dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
Dir.entries(dir_path).each do |path|
  if path != File.basename(__FILE__) and path[-3..-1] == '.rb'
    require(path)
  end
end

# Starting the Cocoa main loop.
NSApplicationMain(0, nil)
