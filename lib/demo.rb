require 'badge.rb'


message1 = "Hiya!"
message2 = "Hello everyone! This is a really long message that takes up more than 64 characters. It will require multiple update packets."

# You need to know the device name - should look something like "/dev/ttyUSB0" if you are using linux. 
badge = B1236Badge.new "/dev/ttyUSB0"

badge.set_message message1

sleep 10

badge.set_message message2