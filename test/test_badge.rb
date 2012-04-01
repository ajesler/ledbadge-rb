require 'test/unit'
require '../lib/badge.rb'

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
		p = Packet.new(0x00, d)
		f = p.format
		assert_equal("\x02\x31\x06\x00\x35\x31\x41\x04AAAA\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\346", f)
		#                                                 ^ from here on is the message padding to get it to 64 chars
	end

	def test_packet_format2
		d = "\x35\x31\x41\x04Hello, world!"
		p = Packet.new(0x00, d)
		f = p.format
		assert_equal("\x02\x31\x06\x00\x35\x31\x41\x04Hello, world!\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000k", f)
		#                                                          ^ from here on is the message padding to get it to 64 chars
	end

	def test_packet_checksum
		d = []
		p = Packet.new(0x00, d)
		c = p.checksum
		# TODO
	end


# BADGE TESTS
	# you may have to set this correctly before tests will run
	B = B1236.new "/dev/ttyUSB0" 

	def test_buildPayload
		d = "Hello!"
		o = B.build_payload d
		assert_equal("\005\001B\006Hello!", o)
	end

	def test_buildPayload_with_speed
		d = "Hello!"
		o = B.build_payload(d, {:speed=>1})
		assert_equal("\001\001B\006Hello!", o)
	end

	def test_buildPayload_with_index
		d = "Hello!"
		o = B.build_payload(d, {:msgindex=>4})
		assert_equal("\005\004B\006Hello!", o)
	end

	def test_buildPayload_with_index_too_low_zero
		d = "Hello!"
		assert_raise_message RuntimeError, /index must be between 1 and 6/ do
			B.build_payload(d, {:msgindex=>0})
		end
	end

	def test_buildPayload_with_index_too_low
		d = "Hello!"
		assert_raise_message RuntimeError, /index must be between 1 and 6/ do
			B.build_payload(d, {:msgindex=>-1})
		end
	end

	def test_buildPayload_with_index_too_high
		d = "Hello!"
		assert_raise_message RuntimeError, /index must be between 1 and 6/ do
			B.build_payload(d, {:msgindex=>7})
		end
	end

	def test_buildPayload_with_action
		d = "Hello!"
		o = B.build_payload(d, {:action=>LedActions::SNOW})
		assert_equal("\005\001C\006Hello!", o)
	end

	def test_buildPayload_with_all_options
		d = "Hello!"
		o = B.build_payload(d, {:speed=>4,:msgindex=>3,:action=>LedActions::FLASH})
		assert_equal("\004\003D\006Hello!", o)
	end


# TEST HELPER METHODS

	def assert_raise_message(types, matcher, message = nil, &block)
		args = [types].flatten + [message]
		exception = assert_raise(*args, &block)
		assert_match matcher, exception.message, message
	end

end