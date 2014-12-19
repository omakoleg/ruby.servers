require 'socket'
require 'optparse'
# require 'ruby-prof'

options = {
  concurrency: 4,
  number: 4,
  request_header: 10,
  response_header: 10
}

OptionParser.new do |opts|
  opts.on("-c", "--concurrency CONN", "Concurrency") do |v|
    options[:concurrency] = v.to_i
  end
  opts.on("-n", "--number CONN", "Number requests per client") do |v|
    options[:number] = v.to_i
  end
  opts.on("-r", "--read SIZE", "Request size. Header size to send within request") do |v|
    options[:request_header] = v.to_i
  end
  opts.on("-w", "--write SIZE", "Response size. Header size to send within response") do |v|
    options[:response_header] = v.to_i
  end
end.parse!
p options

trap(:INT) { exit }
start = Time.now

options[:concurrency].times do 
  pid = fork do
    substart = Time.now
    Socket.tcp('localhost', 1234) do |connection|
      options[:number].times do
        connection.write "GET / HTTP/1.0\r\n" + 
          "Simple-Header-Size: #{options[:response_header]}\r\n" +
          "Simple-Header: #{"a" * options[:request_header]}\r\n\r\n"
        # read all
        loop do
          begin
            data = connection.readpartial(1024*10)
            break if data.end_with?("\r\n\r\n")
          rescue Errno::EAGAIN
            retry # buffen not empty
          rescue EOFError
            break # all data read
          end
        end
      end
      connection.close
    end
    puts "#{(Time.now - substart).round(5)}"
  end
end

Process.waitall
puts "--> #{(Time.now - start).round(5)}"
