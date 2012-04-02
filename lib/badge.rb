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

	def LedActions.from_string(val)
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

class SpecialCharacters
	STAR 	 = "\xc0\x14"
	HEART 	 = "\xc0\x00"
	LEFT 	 = "\xc0\x08"
	RIGHT 	 = "\xc0\x04"
	PHONE1 	 = "\xc0\x06"
	PHONE2 	 = "\xc0\x02"
	SMILE 	 = "\xc0\x0a"
	CIRCLE   = "\xc0\x0c"
	QUESTION = "\xc0\x0e"
	TAIJI 	 = "\xc0\x10"
	MUSIC 	 = "\xc0\x12"
	FULL 	 = "\xc0\x16"

	ALL 	 = STAR+HEART+LEFT+RIGHT+PHONE1+PHONE2+SMILE+CIRCLE+TAIJI+MUSIC+QUESTION+FULL
end

class Packet

	BYTES_PER_PACKET = 64

	attr_accessor :command, :sec, :third, :addressOffset, :data

	def initialize(addressOffset, data)
		@command = 0x02
		@sec = 0x31
		@third = 0x06

		raise "data must be of length #{BYTES_PER_PACKET}" unless data.length == BYTES_PER_PACKET

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

	def set_message(message, opts={})
	
		raise "Message cannot have a length greater than 250 characters. Your message was #{message.length} characters" unless message.length <= 250

		puts "Setting badge message to #{message}"

		payload = build_payload(message, opts)
		packets = build_packets(payload)
		send_packets packets

		puts "Completed"

	end
	# can you clear a message with 0, 2, 0x33, 0 ?

	def build_payload(message, opts={})

		o = {
	     :speed => 5,
	     :msgindex => 1,
	     :action => LedActions::SCROLL
	   }.merge(opts)

		raise 'index must be between 1 and 6' unless o[:msgindex] >= 1 && o[:msgindex] <= 6

		msgFile = [o[:speed].to_s, o[:msgindex].to_s, o[:action], message.length].pack("aaac").bytes.to_a
		msgFile += message.bytes.to_a

		ml = msgFile.length
		pl = Packet::BYTES_PER_PACKET
		# works out the next highest multiple of 64 based on 
		# the message length, and returns the number of 0's 
		# required to pad to this length
		dif = (pl * (((ml - 1) / pl) + 1) ) - ml
		msgFile += [0x00]*dif unless dif <= 0
		#puts "ml=#{ml}, dif=#{dif}, msgFile=#{msgFile.length}"
		msgFile

	end

	def build_packets(payload)

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

		puts "Sent packet of length #{data.length}"

		@port.write data.pack('C*')
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

end