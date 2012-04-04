require 'badge.rb'

include B1236

message1 = "Hiya!"
message2 = "Hello everyone! This is a really long message that takes up more than 64 characters. It will require multiple update packets."

# You need to know the port - should look something like "/dev/ttyUSB0" if you are using linux. 
badge = Badge.new "/dev/ttyUSB1"

puts "Setting message "+Fonts::BOLD+"1"
badge.set_message message1

sleep 5

puts "Setting message 2"
badge.set_message message2

sleep 45

m1 = "Demo 1"
m2 = "Demo 2"
m3 = "D 3"
m4 = "Demo 4"
m5 = "Demo 5"
m6 = "Demo 6"

messages = [[m1], [m2, {:speed => 3}], [m3, {:action => LedActions::SNOW}], [m4], [m5], [m6]]
puts "setting multiple messages"
badge.set_messages messages

sleep 45

alternatingFont = "Hi! "+Fonts::BOLD+"Hello in bold "+Fonts::NORMAL+" now its normal again"
puts "Setting new message which will wipe all previous messages"
badge.set_message(alternatingFont)