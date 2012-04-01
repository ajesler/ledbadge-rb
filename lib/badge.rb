require 'rubygems'
require 'enumerator'
require 'serialport'
require 'RMagick'

include Magick

# Available actions for displaying the message
class LedActions
	HOLD 	  = 'A'
	SCROLL 	  = 'B'
	SNOW 	  = 'C'
	FLASH	  = 'D'
	HOLDFRAME = 'E'

	def LedActions.fromString(val)
		raise "Invalid LedAction #{val}" unless ALL.has_key? val
		ALL[val]
	end

	private 
	ALL = {
		'HOLD' => HOLD,
		'SCROLL' => SCROLL,
		'SNOW' => SNOW,
		'FLASH' => FLASH,
		'HOLDFRAME' => HOLDFRAME
	}
end

class Fonts
	NORMAL = "\xff\x80"
	BOLD   = "\xff\x81"
end

class Packet

	BYTES_PER_PACKET = 64

	attr_accessor :command, :sec, :third, :addressOffset, :data

	def initialize(addressOffset, data)
		@command = 0x02
		@sec = 0x31
		@third = 0x06

		@addressOffset = addressOffset
		@data = data
	end

	def format
		d = [@command, @sec, @third, @addressOffset].pack("cccc").bytes.to_a
		d += @data
		checksum = calcChecksum(d[1..d.length])
		puts "checksum is #{checksum}"
		d << checksum
	end

	def calcChecksum(data)
		# assumes that data is an array of bytes (fixnums?)

		val = data.inject(0) do |sum,item| 
			#puts "#{sum}: #{sum.class} - #{item.class}"
			sum + item
		end
		val &= 0xff
		# should return a single byte
	end

end

class B1236

	SERIAL_PARAMS = { "stop_bits" => 1, "parity" => SerialPort::NONE, "baud" => 38400 }

	attr_accessor :device_name, :port

	def initialize(device_name)
		@device_name = device_name
		@port = SerialPort.new(@device_name, SERIAL_PARAMS)
	end

	def closePort
		@port.close
	end

	def setMessage(message, opts={})
	
		raise "Message cannot have a length greater than 250 characters. Your message was #{message.length} characters" unless message.length <= 250

		puts "Setting badge message to #{message}"

		badgePayload = buildPayload(message, opts)
		packets = buildPackets(badgePayload)
		send_packets packets

		puts "Completed"

	end
	# can you clear a message with 0, 2, 0x33, 0 ?

	def buildPayload(message, opts={})

		o = {
	     :speed => 5,
	     :msgindex => 1,
	     :action => LedActions::SCROLL
	   }.merge(opts)

		raise 'index must be between 1 and 6' unless o[:msgindex] >= 1 && o[:msgindex] <= 6

		msgFile = [o[:speed].to_s, o[:msgindex].to_s, o[:action], message.length].pack("aaac").bytes.to_a
		msgFile += message.bytes.to_a

		dif =  254 - msgFile.length #Packet::BYTES_PER_PACKET - msgFile.length
		msgFile += [0x00]*dif unless dif <= 0

	end

	def buildPackets(payload)

		packets = Array.new
		addressOffset = 0x00

		puts "payload length: #{payload.length}"

		payload.each_slice(64) do |part|

			puts "part length = #{part.length}"

			p = Packet.new(addressOffset, part)
			packets.push p

			addressOffset += 0x40

		end

		packets

	end

	def send_packets(packets)
		sent = []

		initial = [0x00]

		# send initial byte
		send_data(initial, sent)

		# send packets to the badge
		i = 0
		packets.each do |p|
			i += 1
			puts "Sending packet #{i} / #{packets.length}"
			#@port.write p.format
			send_data(p.format, sent)
		end

		# write closing sequence
		send_data([0x02,0x33,0x01], sent)

		print_sent_data(sent)

	end

	def send_data(data, arr)
		s = data.collect{ |v| sprintf("%02X ", v) }

		puts "Sent packet of length #{data.length} #{data.join}"

		@port.write data.join
		arr << data
	end

	def print_sent_data(arr, packet_sep = "")
		result = ""

		dataSize = 0

		arr.each do |p|
			dataSize += p.length
			p.each do |h|
				result += sprintf("%02X ", h)
			end
			result += packet_sep
		end

		puts result
	end

	def test_write 
		data = [0x00, 0x02, 0x31, 0x06, 0x00, 0x35, 0x31, 0x42, 0x02, 0x48, 0x69, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x92, 0x02, 0x31, 0x06, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x77, 0x02, 0x31, 0x06, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xb7, 0x02, 0x31, 0x06, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf7, 0x02, 0x33, 0x01]
		@port.write data
	end

	def test_write_hex
		to = %w(00 02 31 06 00 35 31 42 02 48 69 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 92 02 31 06 40 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 77 02 31 06 80 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 b7 02 31 06 c0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 f7 02 33 01).map{|s| s.hex}.pack('C*')
		@port.write to
	end

end