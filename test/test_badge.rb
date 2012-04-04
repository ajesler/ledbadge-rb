require 'test/unit'
require '../lib/badge.rb'

include B1236

class BadgeTests < Test::Unit::TestCase

# LEDActions TESTS

	def test_fromString_SCROLL
		s = 'SCROLL'
		n = LedActions.from_string s
		assert_equal(LedActions::SCROLL, n)
	end

	def test_fromString_HOLDFRAME
		s = 'HOLDFRAME'
		n = LedActions.from_string s
		assert_equal(LedActions::HOLDFRAME, n)
	end

	def test_fromString_INVALID
		s = 'I'
		assert_raise_message RuntimeError, /Invalid LedAction/ do
			LedActions.from_string s
		end
	end


# PACKET TESTS

	def test_packet_format
		d = "\x35\x31\x41\x04AAAA"
		d += "\x00"*(Packet::BYTES_PER_PACKET - d.length)
		p = Packet.new(0x00, 0x60, d)
		f = p.format
		assert_equal("\x02\x31\x06\x00\x35\x31\x41\x04AAAA\346", f)
	end

	def test_packet_format2
		d = "\x35\x31\x41\x04Hello, world!"
		p = Packet.new(0x00, 0x60, d)
		f = p.format
		assert_equal("\x02\x31\x06\x00\x35\x31\x41\x04Hello, world!k", f)
	end

	def test_packet_checksum
		d = []
		p = Packet.new(0x00, 0x60, d)
		c = p.checksum
		# TODO
	end


# BADGE TESTS
	# you may have to set this correctly before tests will run
	B = Badge.new "/dev/ttyUSB1" 

	def build_payload
		d = "Hello!"
		e = "\005\001B\006Hello!"
		o = B.build_payload d
		assert_equal(e.bytes, o)
	end

	def test_build_payload_with_speed
		d = "Hello!"
		e = "\001\001B\006Hello!"+"\x00"*54
		o = B.build_payload(d, {:speed=>1})
		assert_equal(e.bytes, o)
	end

	def test_build_payload_with_index
		d = "Hello!"
		e = "\005\004B\006Hello!"+"\x00"*54
		o = B.build_payload(d, {:msgindex=>4})
		assert_equal(e.bytes, o)
	end

	def test_build_payload_with_index_too_low_zero
		d = "Hello!"
		assert_raise_message RuntimeError, /index must be between 1 and 6/ do
			B.build_payload(d, {:msgindex=>0})
		end
	end

	def test_build_payload_with_index_too_low
		d = "Hello!"
		assert_raise_message RuntimeError, /index must be between 1 and 6/ do
			B.build_payload(d, {:msgindex=>-1})
		end
	end

	def test_build_payload_with_index_too_high
		d = "Hello!"
		assert_raise_message RuntimeError, /index must be between 1 and 6/ do
			B.build_payload(d, {:msgindex=>7})
		end
	end

	def test_build_payload_with_action
		d = "Hello!"
		e = "\005\001C\006Hello!"+"\x00"*54
		o = B.build_payload(d, {:action=>LedActions::SNOW})
		assert_equal(e.bytes, o)
	end

	def test_build_payload_with_all_options
		d = "Hello!"
		e = "\004\003D\006Hello!"+"\x00"*54
		o = B.build_payload(d, {:speed=>4,:msgindex=>3,:action=>LedActions::FLASH})
		assert_equal(e.bytes, o)
	end


# TEST HELPER METHODS

	def assert_raise_message(types, matcher, message = nil, &block)
		args = [types].flatten + [message]
		exception = assert_raise(*args, &block)
		assert_match matcher, exception.message, message
	end

end