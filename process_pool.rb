require 'socket'
require 'colorize'
require './common'

class ProcessPoolServer
  include Common
  CONCURRENCY = 4
  
  def run
    trap(:INT) {
      @child_pids.each do |cpid|
        begin
          Process.kill(:INT, cpid)
        rescue Errno::ESRCH
        end
      end
      exit
    }
    
    @child_pids = []
    CONCURRENCY.times do
      @child_pids << spawn_child
    end
    
    loop do
      pid = Process.wait
      $stderr.puts "Process #{pid} quit unexpectedly"
      @child_pids.delete(pid)
      @child_pids << spawn_child
    end
  end
    
  
  def spawn_child
    fork do
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

ProcessPoolServer.new.run
