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
      end # thread
    end
  end
end

trap(:PIPE){ exit }
trap(:INT){ exit }
Thread.abort_on_exception = true
ThreadServer.new.run
