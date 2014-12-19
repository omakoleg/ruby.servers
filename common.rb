require 'colorize'

module Common
  def initialize
    @control_socket = TCPServer.new(1234)
  end

  class Client
    attr_reader :client, :color
    
    def initialize(client)
      @client = client
      @color = (String.colors - [:black]).sample
    end
    
    def handle
      request = ""
      loop do
        begin
          request << @client.readpartial(1024*10)
          break if request.end_with?("\r\n\r\n")
        rescue Errno::EAGAIN
          retry # buffen not empty
        rescue EOFError
          break # all data read
        end
      end
      request
    end
    
    def process
      @client.write "HTTP/1.1 200 OK\r\n" +
           "Content-Type: text/plain\r\n" +
           "Content-Length: 2\r\n" +
           "Connection: close\r\n\r\nok"
    end
    
    def msg_connect
      puts "-->".colorize(@color)
    end
    
    def msg_request(req = nil)
      puts "[request]".colorize(@color)
    end
    
    def msg_disconnect
      puts "<--".colorize(@color)
    end
  end
end
