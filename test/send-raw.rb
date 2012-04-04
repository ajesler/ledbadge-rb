require '../lib/badge.rb'

include B1236


badge = Badge.new "/dev/ttyUSB1"

t = Time.now.to_i.to_s[4..9]

badge.set_message t