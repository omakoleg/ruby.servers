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
        req = client.handle
        if req.end
          client.msg_request(req)
          client.process
        else
          client.msg_disconnect
          client.client.close
          break
        end
      end
    end
  end
end

trap(:INT) { exit }
SimpleServer.new.run
