require '../lib/badge.rb'


# should produce A bold B normal C bold D normal E
alternatingChars = "\x41\xff\x81\x42\xff\x80\x43\xff\x81\x44\xff\x80\x45"

alternatingFont = "Hi! "+Fonts::BOLD+"Hi in bold "+Fonts::NORMAL+"normal again2"
l10 = "abcdefghij"
full = ""+SpecialCharacters::FULL
repeated = "1234"*47


# You need to know the device name 
#should look something like "/dev/ttyUSB0" if you are using linux. 
badge = B1236.new "/dev/ttyUSB0"

t = Time.now.to_i.to_s[4..9]

badge.set_message repeated