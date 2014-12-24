# About

Repository for server implementation examples. Read book `Working with TCP sockets` most of the exaples based on it.
Implemented few approaches:
- Simple server `ruby simple.rb`. Accept connection and perform all requests for particular user. All other connections wait. Blocking example.
- Threaded server `ruby thread.rb`. Spawn new thread for each client connection. Example of GIL influence.
- Process server `ruby process.rb`. Spawn new process (duplicate current) for each client connection. Output looks like `threaded` approach but GIL not affecting it.
- Process pool server `ruby process_pool.rb`. Spawn N processes in the setup process and handle process exception exits with re-spawning new one. Works like `process server`
- Thread server `ruby thread_pool.rb`. Spawn N threads un setup and accept each same as `thread` example. Simple implementation without re-spawning threads.
- Reactor server `ruby reactor.rb`. Most intresting example with non-blocking approach. Aka Thin (nodejs) core principle. 

For testing purposes created simple threaded client for making requests.
`ruby client.rb -c 10 -n 10 -r 1000 -w 10000`
- `c` number of concurrent threads 
- `n` number of requests within each thread. Requests performed withoud dropping connection.
- `r` size of request header. Make sense to specify size more than 16kb to fill accept buffers.
- `w` size of responce header. Number could be bigger to see partitioning on server side because write buffers quite bigger then read ones.

# Server output

Usual server log will looks like this (example from `thread.rb`):
`+  +  + ..|.||..||...|||..|.|.||.|.|..||...|.|||..|.|.|.|.|.|.|| - .|.| -  - `

Client where run with:
`ruby client.rb -n 10 -c 3`

Output has different colors for each client connection.

Where:
- `+` client establish connection
- `-` client disconnects
- `.` server read chunk of message (or full message) 
- `|` server write response (or its part)


# Protocol

Main protocol looks like regular http but big data chunks placed to header values.
This used because of reducing logic for looking `Content-length` value and read this amount of data. Using Header only approach gives us defined protocol message end border. Http header separated by `\r\n\r\n` and this combination is uqnique inside message.

### Request 
Request message looks like:
```
GET / HTTP/1.0\r\n
Simple-Header-Size: 10\r\n
Simple-Header: aaaaaaaaaa\r\n
\r\n
```
Empty request will close connection on a server side. Quite simple approach, just check each request body before processing response.

### Response 

Response message:
```
HTTP/1.1 200 OK\r\n
Content-Type: text/plain\r\n
Simple-Header-Response: aaaaaaaaaa\r\n
\r\n
```

Where `Simple-Header-Response` value is generated by server using number from request `Simple-Header-Size`

# Licence

MIT