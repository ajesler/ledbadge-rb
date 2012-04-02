require 'badge.rb'
require 'trollop'


opts = Trollop::options do
  opt :device, "The name of the serial port to connect to", :type => :string
  opt :speed, "The speed of the action (1-5)", :type => :int
  opt :index, "The index of the message to set (1-6)", :type => :int
  opt :action, "The action to use (HOLD|SCROLL|SNOW|FLASH|HOLDFRAME)", :type => :string
end

# make sure we have a message to set
if ARGV.empty?
	puts "Please call this script with the message you want to set on the badge as the argument"
	exit
end

if !opts[:action].nil?
	# get the correct action if one was set
	opts[:action] = LedActions.from_string opts[:action]
end

# get the device name or use the default
device = opts[:device] || "/dev/ttyUSB0"

# remove unset options
opts.reject!{ |key, value| value == nil}

# create a new device
updater = B1236Badge.new device
# set the messages, with the set options
updater.set_message(ARGV[0], opts)