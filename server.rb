require 'socket'
require './handler'

class Server

  def initialize
    @handler = Handler.new

    @events_connections_server = TCPServer.open  9090
    @user_connections_server = TCPServer.open 9099

    Thread.fork { listen_user_connections }
    events_thread = listen_events_connections
    events_thread.join
  end

  private

  def listen_user_connections
    loop {
      Thread.fork(@user_connections_server.accept) do |socket|
        id = socket.gets.chomp
        @handler.connect_user id, socket
      end
    }.join
  end

  def listen_events_connections
    Thread.fork(@events_connections_server.accept) do |socket|
      while payload = socket.gets
        payload = payload.chomp
        @handler.add_event payload
      end
    end
  end
end

puts "Initializing server..."
Thread.abort_on_exception = true
Server.new
