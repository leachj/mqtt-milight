require 'socket'
require 'mqtt'

class MilightSender

	def initialize(ip)
		@onCommands = [0x42,0x45,0x47,0x49,0x4B]
		@offCommands = [0x41,0x46,0x48,0x4A,0x4C]
		@whiteCommands = [0xC2,0xC5,0xC7,0xC9,0xCB]
		@ip = ip
	end

	def on(channel)
		send [@onCommands[channel],0x00,0x55]
	end

	def off(channel)
		send [@offCommands[channel],0x00,0x55]
	end

	def dim(channel, percent)
		send [@onCommands[channel],0x00,0x55]
		dimValue = 0x02 + (0.25 * percent)
		send [0x4E,dimValue,0x55]
	end

	def colour(channel, colour)
		send [@onCommands[channel],0x00,0x55]
		send [0x40,colour,0x55]
	end
	
	def white(channel)
		send [@onCommands[channel],0x00,0x55]
		send [@whiteCommands[channel],0x00,0x55]
	end

	def send(bytes)
		s = UDPSocket.new 
		3.times do
			s.send(bytes.pack('C*'),0,@ip, 8899)
			sleep(0.1)
		end
		s.close
	end
end



MQTT::Client.connect('192.168.1.70') do |c|
 
   c.subscribe('milight-control')
   c.get do |topic,message|
   	puts "#{topic}: #{message}"
	ip = message.split(" ")[0]
	channel = message.split(" ")[1].to_i
	command = message.split(" ")[2]
	sender = MilightSender.new(ip)
	if(command == "on")
		sender.on(channel)
	elsif(command == "dim")
		percent = message.split(" ")[3].to_i
		sender.dim(channel, percent)
	elsif(command == "colour")
		colour = message.split(" ")[3].to_i
		sender.colour(channel, colour)
	elsif(command == "white")
		sender.white(channel)
	else
		sender.off(channel)
   	end
   end
end
