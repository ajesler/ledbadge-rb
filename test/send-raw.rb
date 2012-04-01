require '../lib/badge.rb'


# should produce A bold B normal C bold D normal E
alternatingChars = "\x41\xff\x81\x42\xff\x80\x43\xff\x81\x44\xff\x80\x45"

userAlternatingFont = "Hi! "+Fonts::BOLD+"Hi in bold "+Fonts::NORMAL+"normal again"

l10 = "abcdefghij"
l11 = "abcdefghijk"
l12 = "abcdefghijkl"
l13 = "abcdefghijklm"
l14 = "abcdefghijklmn"

# You need to know the device name 
#should look something like "/dev/ttyUSB0" if you are using linux. 
badge = B1236.new "/dev/ttyUSB0"

#badge.setMessage alternatingChars
#badge.setMessage userAlternatingFont

t = Time.now.to_i.to_s[4..9]
puts "t=#{t}" 
badge.setMessage t

badge.setImage "test-images/12x12-black.bmp" 