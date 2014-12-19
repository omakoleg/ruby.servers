require 'socket'
require 'thread'
require './common'


class ThreadPoolServer
  include Common
  CONCURRENCY = 4 # could be bigger
  
  def run
    trap(:INT) { exit }
    Thread.abort_on_exception = true
    threads = ThreadGroup.new
    CONCURRENCY.times do
      threads.add spawn_child
    end
    sleep # lock from exit
  end    
  
  def spawn_child
    Thread.new do
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
        end # messages loop
      end# loop
    end # fork
  end
end

ThreadPoolServer.new.run
