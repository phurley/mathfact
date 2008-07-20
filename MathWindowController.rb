#
#  MathWindowController.rb
#  mathfact
#
#  Created by Patrick Hurley on 6/19/08.
#  Copyright (c) 2008 Patrick Hurley. All rights reserved.
#

require 'osx/cocoa'

class Foo < OSX::NSObject
end

class MathWindowController < OSX::NSWindowController

  include OSX
  ib_outlets :prefsWindow, :mainWindow
  ib_outlets :do_add, :do_sub, :do_mul, :do_div
  ib_outlets :do_timer, :time_limit
  ib_outlets :min_num, :max_num, :num_problems
  ib_outlets :min_num_label, :max_num_label
  ib_outlets :num_problems_label, :timer_label

  def getbool(tag, default=true)
    val = @defaults[tag]
    return default unless val
    val.to_i == 1
  end

  def getint(tag, default=0)
    val = @defaults[tag]
    return default unless val
    val.to_i
  end

  def walk_children(view)
    if view.is_a?(NSSlider)
      puts "  we have a slider -- #{view.description}"
      puts view.objc_methods.grep(/selector/i).sort.join("\n")
#      view.doCommandBySelector("selector:")      
   #   view.doCommandBySelector("takeIntValueFrom:")      
    end
    
    if view.is_a?(NSView)
      view.subviews.each do |child|
        walk_children(child)
      end
    end
  end
    
  # called from the instansiated object in the mainController object
  # (IBAction)  
  def displaySheet(sender)
    puts('opening sheet')
    NSBundle.loadNibNamed_owner('prefs', self)
    
    @defaults ||= NSUserDefaults.standardUserDefaults

    @num_problems.intValue = getint("problem_count", 25)
    @num_problems_label.setTitleWithMnemonic(@num_problems.intValue.to_s)
    
    @min_num.intValue = getint("min_number", 2)
    @min_num_label.setTitleWithMnemonic(@min_num.intValue.to_s)
    
    @max_num.intValue = getint("max_number", 12)
    @max_num_label.setTitleWithMnemonic(@max_num.intValue.to_s)

    @time_limit.intValue = getint("time_limit", 180)
    @timer_label.setTitleWithMnemonic(@time_limit.intValue.to_s)
    
    @do_timer.state = getint("use_timer", 1)
    
    @do_add.state = getint("do_add", 1)
    @do_mul.state = getint("do_mul", 1)
    @do_sub.state = getint("do_sub", 1)
    @do_div.state = getint("do_div", 1)
    
    #walk_children(@prefsWindow.contentView)
    
    NSApp.beginSheet_modalForWindow_modalDelegate_didEndSelector_contextInfo(@prefsWindow, @mainWindow, self, :prefsDidEndSheet_returnCode_contextInfo, nil)
  end
  ib_action :displaySheet
  
  # (void)
  def prefsDidEndSheet_returnCode_contextInfo(sheet, returnCode, context)
    puts("Running the callback, put some code here: #{returnCode}")

    sheet.orderOut(nil)
    puts('Sheet closed')
    puts @min_num.intValue
    p @do_add.state

    defaults = NSUserDefaults.standardUserDefaults
    defaults["do_add"] = @do_add.state
    defaults["do_sub"] = @do_sub.state
    defaults["do_mul"] = @do_mul.state
    defaults["do_div"] = @do_div.state
    
    defaults["problem_count"] = @num_problems.intValue
    defaults["min_number"] = @min_num.intValue
    defaults["max_number"] = @max_num.intValue
    defaults["time_limit"] = @time_limit.intValue
    defaults["use_timer"] = @do_timer.state
    
    defaults.synchronize
    
    window.reset
  end
  
  # (IBAction)
  #def submitSheet(sender)
  #  
  #end
  
  # called in the sheet NIB
  # (IBAction)
  def closeSheet(sender)
    puts sender
    puts sender.title
    NSApp.endSheet_returnCode(@prefsWindow, sender.title == "Cancel" ? 0 : 1)
  end
  ib_action :closeSheet

end
