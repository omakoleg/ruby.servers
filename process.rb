require 'socket'
require './common'

class ProcessServer
  include Common
  
  def run
    loop do
      @socket = @control_socket.accept
      pid = fork do 
        client = Client.new(@socket)
        client.msg_connect
        loop do
          req = client.handle
          if req && req != ""
            client.msg_request(req)
            client.process
          else
            client.msg_disconnect
            client.client.close
            break
          end
        end
      end # fork
    end
  end
end

trap(:INT){ exit }
ProcessServer.new.run
