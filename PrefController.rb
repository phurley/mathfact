#
#  PrefController.rb
#  mathfact
#
#  Created by Patrick Hurley on 6/19/08.
#  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
#

require 'osx/cocoa'

class PrefController < OSX::NSWindowController

    def checkRange(sender)
      puts "Check Range"
    end
    ib_action :checkRange
end
