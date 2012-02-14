require 'rubygems'
require 'serialport'

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

class Packet

	attr_accessor :command, :sec, :third, :addressOffset, :data

	def initialize(addressOffset, data)
		@command = 0x02
		@sec = 0x31
		@third = 0x06

		@addressOffset = addressOffset
		@data = data
	end

	def format
		d = [@command, @sec, @third, @addressOffset, @data].pack("cccca64")
		d += calcChecksum(d[1..d.length]).chr
	end

	def calcChecksum(data)
		val = data.bytes.inject(0){|sum,item| sum + item}
		val &= 0xff
	end

end

class B1236

	ADDRESS_START = 0x600 # this is the starting address of the memory containing message data?
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
		packets = buildPackets(ADDRESS_START, badgePayload)
		sendData packets

	end

	# can you clear a message with 0, 2, 0x33, 0 ?

	def buildPayload(message, opts={})

		o = {
	     :speed => 5,
	     :msgindex => 1,
	     :action => LedActions::SCROLL
	   }.merge(opts)

		raise 'index must be between 1 and 6' unless o[:msgindex] >= 1 && o[:msgindex] <= 6

		msgFile = [o[:speed], o[:msgindex], o[:action], message.length].pack("ccac")
		msgFile += message
	end

	def buildPackets(address, payload)

		packets = Array.new
		addressOffset = 0x00

		payload.scan(/.{1,64}/).each do |part|

			p = Packet.new(addressOffset, part)
			packets.push p

			addressOffset += 0x40

		end

		packets

	end

	def sendData(packets)
		
		# send initial byte
		@port.write 0x00

		# send packets to the badge
		i = 0
		packets.each do |p| 
			d = p.format
			i += 1
			puts "Sending packet #{i} / #{packets.length}"
			@port.write p.format 
		end

		# write closing sequence
		@port.write [0x02,0x33,0x01]

	end

end