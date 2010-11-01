require 'socket'

namespace :memcached do
  desc "Flush memcached (running on default port 11211)"
  task :flush do
    socket = TCPSocket.new( '127.0.0.1', 11211 )
    socket.write( "flush_all\r\n" )
    result = socket.recv(2)
    puts "memcached flushed." if result == 'OK'
    socket.close
  end
end
