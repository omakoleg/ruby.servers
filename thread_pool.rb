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
          req = client.handle
          if req && req != ""
            client.msg_request(req)
            client.process
          else
            client.msg_disconnect
            client.client.close
            break # jump to accept
          end
        end # messages loop
      end# loop
    end # fork
  end
end

ThreadPoolServer.new.run
