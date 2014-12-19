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
      end # fork
    end
  end
end

trap(:INT){ exit }
ProcessServer.new.run
