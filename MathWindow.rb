#
#  MathWindow.rb
#  mathfact
#
#  Created by Patrick Hurley on 6/17/08.
#  Copyright (c) 2008 HurleyHome LLC. All rights reserved.
#

require 'osx/cocoa'
require 'time'
require 'thread'
require 'pp'

class MathWindow < OSX::NSWindow
  include OSX
  ib_outlet :problem
  ib_outlet :problem_count
  ib_outlet :correct_label
  ib_outlet :elapsed
  ib_outlet :remaining
  ib_outlet :progress_bar
  
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
  
  def get_defaults
    @expr = "Press Enter to Start"
    @guess = ""
    @stopped = false
    @started = false
    @correct = 0
    @count = 0
    @start = nil
    
    @defaults ||= NSUserDefaults.standardUserDefaults
    @problems = getint("problem_count", 50)
    @max_num = getint("max_number", 12)
    @min_num = getint("min_number", 2)
    @timer = getbool("use_timer", false)
    @time_limit = getint("time_limit", 180)
    
    @do_add = getbool("do_add")
    @do_mul = getbool("do_mul")
    @do_sub = getbool("do_sub")
    @do_div = getbool("do_div")
    
    @progress_bar.setMaxValue(@problems)
    
    update_status
  end
  
  def awakeFromNib
    puts "initialize #{self}"
    @mutex = Mutex.new
    @synth = NSSpeechSynthesizer.alloc.init
    get_defaults
    
    Thread.new do
      thread_body
    end
  end
  
  def set(label, value)
    if label
      label.setTitleWithMnemonic(value.to_s)
    end
  end

  def update_status
    @mutex.synchronize do 
      if @count == 0
        set(@correct_label, "0 (100%)")
      else
        set(@correct_label, "%d (%0.2f%%)" % [@correct, (@correct.to_f / @count.to_f * 100.0)])
      end
      set(@problem_count, "#{@count} of #{@problems}")
      
      elapse = Time.now - @start rescue 0

      unless @stopped
        set(@elapsed, "%d" % [elapse])
        set(@remaining, (@time_limit - elapse).to_i)
      end
      
      if (elapse >= @time_limit) && @timer
        @stopped = true
        @expr = "Times up, nice try"
        @guess = ""
      end
      
      @progress_bar.doubleValue = @count.to_f
      @problem.setTitleWithMnemonic(@expr + @guess)
      
    end
  rescue
    puts "Udpate status -- #{$!} -- #{$!.backtrace.join("\n")}"
  end
  
  def thread_body
    while true
      update_status
      sleep 0.5
    end
  rescue
    puts "Ouch #{$!}"
  end
  
  def reset
    get_defaults
  end
  ib_action :reset
  
  def keyDown(event)
    unless @started
      @started = true
      @stopped = false
      @start = Time.now
      @expr,@answer = get_problem
      @guess = ""
      @problem.setTitleWithMnemonic(@expr + @guess)
    end
      
    case event.characters[0]
    when 13,3
      unless @guess.empty?
        if @guess.to_i == @answer
          @correct += 1
          NSSound.soundNamed("Ping").play
        else
          text = @expr.sub("+", "plus")
          text = text.sub("-", "minus")
          text = text.sub("×", "times")
          text = text.sub("÷", "divided by")
          @synth.startSpeakingString("Oops #{text} is #{@answer}")
        end
        @count += 1
        self.title = "#{@count} problem#{@count > 1 ? "s" : ""} out of #{@problems}"
          
        @expr,@answer = get_problem
        @guess = ""
        
        if @count >= @problems
          stop = Time.now
          if @problems == @correct
            @synth.startSpeakingString("Good job you got them all right")
          elsif (@problems - @correct) < 3
            @synth.startSpeakingString("Not bad you only got #{@problems - @correct} wrong")
          else
            @synth.startSpeakingString("Thanks for practicings, keep trying.")
          end
          @expr = ""
          elaps = "%3.02f" % [stop - @start]
          @guess = "Finished in #{elaps} seconds"
          @started = false        
        end
      end
      
    when 4, 8, 32, 127, 63272
      @guess = @guess[0...-1]
      
    else
      if %W(0 1 2 3 4 5 6 7 8 9).include?(event.characters)
        @guess += event.characters
      end
    end
    
#    @problem.setTitleWithMnemonic(@expr + @guess)
    update_status
    
    if event.characters == "q"
      close
    end
  end

private
  def get_rand 
    rand(@max_num - @min_num + 1) + @min_num
  end
  
  def get_problem
    ans = nil
    x = get_rand
    y = get_rand

    ops = []
    ops << :+ if @do_add
    ops << :- if @do_sub
    ops << :* if @do_mul
    ops << :/ if @do_div
    ops = [:+, :-, :*, :/] if ops.empty?
    p ops
    
    case ops[rand(ops.size)]
    when :+
      expr = "#{x} + #{y} = "
      ans = x + y
      
    when :-
      ans = x
      x = x + y
      expr = "#{x} - #{y} = "
      
    when :*
      expr = "#{x} × #{y} = "
      ans = x * y
      
    when :/
      ans = x
      x = x * y
      expr = "#{x} ÷ #{y} = "
      
    end
      
    [expr, ans]
  end
end

