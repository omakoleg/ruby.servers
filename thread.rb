require 'socket'
require './common'

class ThreadServer
  include Common
  
  def run
    loop do
      Thread.start(@control_socket.accept) do |socket|  
        client = Client.new(socket)
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
      end # thread
    end
  end
end

trap(:PIPE){ exit }
trap(:INT){ exit }
Thread.abort_on_exception = true
ThreadServer.new.run
