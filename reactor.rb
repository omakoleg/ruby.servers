require 'socket'
require './common'

class ReactorServer
  include Common
  
  
  class ClientConnection < Client
    attr_reader :client, :color
    
    def initialize(client)
      @request, @response = "", ""
      super
    end  
    
    def on_data(data)
      @request << data
      if @request.end_with?("\r\n\r\n")
        @response = get_response(@request)
        @request = ""
      end
    end
    
    def on_writable
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
            connection.msg_request
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
        connection.msg_response
      end
    end
  end
  
end

trap(:INT) { exit }
ReactorServer.new.run
