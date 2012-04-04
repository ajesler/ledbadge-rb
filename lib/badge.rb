require 'rubygems'
require 'enumerator'
require 'serialport'

module B1236

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
	# these are not working properly yet.
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

	attr_accessor :command, :unknown, :address1, :address2, :data

	def initialize(address1, address2, data)
		@command = 0x02
		@uknown = 0x31

		raise "data must be of length #{BYTES_PER_PACKET}" unless data.length == BYTES_PER_PACKET

		@address1 = address1
		@address2 = address2
		@data = data
	end

	def format
		d = [@command, @uknown, @address1, @address2].pack("cccc").bytes.to_a
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

class Badge

	SERIAL_PARAMS = { "stop_bits" => 1, "parity" => SerialPort::NONE, "baud" => 38400 }

	attr_accessor :device_name, :port

	def initialize(device_name)
		@device_name = device_name
		@port = SerialPort.new(@device_name, SERIAL_PARAMS)
	end

	def closePort
		@port.close
	end

	def set_messages(messages)
		raise "Number of messages must be 1-6" unless between_inclusive(1, 6, messages.length)

		# now iterate through the messages, and set them
		packets = []

		index = 1
		address = 0x06

		messages.each do |md|
			# first val is message array, second is opts
			m = md[0]
			mopts = md[1] || {}
			indexopts = { :msgindex => index }
			mopts.merge! indexopts

			p = build_payload(m, mopts)
			packets += build_packets(address, p)

			address += 1

		end

		send_packets(packets, num_messages=messages.length)
	end

	def set_message(message, opts={})
	
		puts "Setting badge message to #{message}"

		payload = build_payload(message, opts)
		packets = build_packets(0x06, payload)
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

	    raise "Message cannot have a length greater than 250 characters. Your message was #{message.length} characters" unless message.length <= 250
		raise 'index must be between 1 and 6' unless between_inclusive(1, 6, o[:msgindex])

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

	def build_packets(address1, payload)

		packets = Array.new
		address2 = 0x00

		puts "payload length: #{payload.length}"

		payload.each_slice(64) do |part|

			puts "part length = #{part.length}"

			p = Packet.new(address1, address2, part)
			packets << p

			address2 += 0x40

		end

		packets

	end

	def send_packets(packets, num_messages=1)
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

		last_byte = lookup_message_count_byte num_messages
		# write closing sequence
		send_data([0x02,0x33,last_byte], sent)

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

	def lookup_message_count_byte(message_count)

		raise "Message count must be between 1 and 8. #{message_count} is an invalid number" unless between_inclusive(1, 8, message_count)

		mapping = {
			1 => 0x01,
			2 => 0x03,
			3 => 0x07,
			4 => 0x0f,
			5 => 0x1f,
			6 => 0x3f,
			7 => 0x7f,
			8 => 0xff
		}

		mapping[message_count]

	end

	def between_inclusive(min, max, val)
		val >= min && val <= max
	end

end

end