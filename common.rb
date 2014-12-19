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
    
    def handle_request
      request = ""
      loop do
        begin
          request << @client.readpartial(1024*2)
          msg_request
          break if request.end_with?("\r\n\r\n")
        rescue Errno::EAGAIN
          IO.select([@client], nil, nil)
          retry # buffen not empty
        rescue EOFError
          break # all data read
        end
      end
      request
    end
    
    def get_response(request)
      size = request[/Simple-Header-Size\:\ ([0-9]*)/, 1]
      size ||= 10
      "HTTP/1.1 200 OK\r\n" +
      "Content-Type: text/plain\r\n" +
      "Simple-Header-Response: #{"a" * size.to_i}\r\n" +
      "\r\n"
    end
    
    def handle_response(response)
      loop do
        begin
          bytes = @client.write_nonblock(response)
          msg_response
          break if bytes >= response.size
          response.slice!(0, bytes)
        rescue Errno::EAGAIN
          IO.select(nil,[@client], nil)
          retry # spam untill send all
        end
      end
    end
    
    def msg_connect
      print " + ".colorize(@color)
    end
    
    def msg_request
      print ".".colorize(@color)
    end
    def msg_response
      print "|".colorize(@color)
    end
    
    def msg_disconnect
      print " - ".colorize(@color)
    end
  end
end
