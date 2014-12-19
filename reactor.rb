require 'socket'
require './common'

class ReactorServer
  include Common
  
  
  class ClientConnection
    attr_reader :client, :color
    
    def initialize(client)
      @client = client
      @request, @response = "", ""
      @color = (String.colors - [:black]).sample
    end
    
    def msg_connect
      print "-->".colorize(@color)
    end
    
    def msg_disconnect
      print "<--".colorize(@color)
    end    
    
    def on_data(data)
      @request << data
      puts "[read]".colorize(@color)
      if @request.end_with?("\r\n\r\n")
        size = @request[/Simple-Header-Size\:\ ([0-9]*)/, 1]
        size ||= 10
        @response = "HTTP/1.1 200 OK\r\n" +
           "Content-Type: text/plain\r\n" +
           "Simple-Header-Response: #{"a"*size.to_i}\r\n" +
           "Connection: close\r\n\r\n"
        @request = ""
      end
    end
    
    def on_writable
      puts "[write]".colorize(@color)
      bytes = client.write_nonblock(@response)
      @response.slice!(0, bytes)
    end
    
    def monitor_for_writing?
      !(@response.empty?)
    end
  end
  
  def run
    @handles = {}
    loop do
      to_read = @handles.values.map(&:client)
      to_write = @handles.values.select(&:monitor_for_writing?).map(&:client)
      readables, writables = IO.select(to_read + [@control_socket], to_write)
      
      readables.each do |socket|
        if socket == @control_socket
          io = @control_socket.accept
          connection = ClientConnection.new(io)
          connection.msg_connect
          @handles[io.fileno] = connection
        else
          connection = @handles[socket.fileno]
          begin
            data = socket.read_nonblock(1024 * 16)
            connection.on_data(data)
          rescue Errno::EAGAIN
          rescue EOFError
            connection.msg_disconnect
            @handles.delete(socket.fileno)
          end
        end
      end
      
      writables.each do |socket|
        connection = @handles[socket.fileno]
        connection.on_writable
      end
    end
  end
  
end

trap(:INT) { exit }
ReactorServer.new.run
