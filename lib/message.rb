require 'badge.rb'
require 'trollop'

include B1236

p = Trollop::Parser.new do
  opt :port, "The name of the serial port to connect to", :type => :string
  opt :speed, "The speed of the action (1-5)", :type => :int
  opt :action, "The action to use (HOLD|SCROLL|SNOW|FLASH|HOLDFRAME)", :type => :string
end

opts = Trollop::with_standard_exception_handling p do
	o = p.parse ARGV
	if ARGV.empty?
		puts "Please call this script with the message you want to set on the badge as the argument"
		raise Trollop::HelpNeeded if ARGV.empty? # show help screen
	end
	o
end

if opts[:action]
	# get the correct action if one was set
	opts[:action] = LedActions.from_string opts[:action]
end

# get the device name or use the default
port = opts[:port] || "/dev/ttyUSB0"

# remove unset options
opts.reject!{ |key, value| value == nil}

# create a new device
updater = Badge.new port
# set the messages, with the set options
updater.set_message(ARGV[0], opts)