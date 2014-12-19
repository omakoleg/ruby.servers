require 'socket'
require './common'

class SimpleServer
  include Common
  
  def run
    loop do
      @socket = @control_socket.accept
      client = Client.new(@socket)
      client.msg_connect
      loop do
        request = client.handle_request
        if request.empty?
          client.msg_disconnect
          client.client.close
          break
        else
          resp = client.get_response(request)
          client.handle_response(resp)
        end
      end
    end
  end
end

trap(:INT) { exit }
SimpleServer.new.run
