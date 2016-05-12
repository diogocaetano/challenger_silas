require 'logger'
require 'monitor'
require './event'
require './user'

class Handler

  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO

    @queue = []
    @queue.extend(MonitorMixin)
    @queue_cond = @queue.new_cond

    @connections = {}
    @users = {}

    @available_events = {}
    @next_seq = 1
    Thread.fork do
      run
    end
  end

  def add_event(payload)
    @logger.info "Payload #{payload} received"
    @queue.synchronize do
      @queue << payload
      @queue_cond.signal
    end
  end

  def connect_user(id, socket)
    user = User.new id
    @connections[id] = socket
    @users[id] = user
    @logger.info "User #{id} connected"
  end

  private

  def run
    loop {
      payload = fetch
      event = Event.new payload
      @logger.info "Payload #{payload} parsed"
      @available_events[event.seq] = event
      next_event = @available_events[@next_seq]
      until next_event.nil?
        send_notification next_event
        if next_event.type == :unfollow
          @logger.info "#{next_event.seq}. #{next_event.type.to_s.capitalize} request completed"
        else
          @logger.info "#{next_event.seq}. #{next_event.type.to_s.capitalize} notification sent"
        end
        @available_events.delete @next_seq
        @next_seq += 1
        next_event = @available_events[@next_seq]
      end
    }.join
  end

  def send_notification(event)
    if event.type == :broadcast
      connections = @connections.values
    elsif event.type == :status_update
      user = @users[event.from]
      connections = []
      if user
        user.followers.each do |id|
          connections << @connections[id] if @connections[id]
        end
      end
    elsif event.type == :follow
      follower = @users[event.from]
      user = @users[event.to]
      if user
        connections = [@connections[user.id]]
        user.add_follower follower if follower
      else
        connections = []
      end
    elsif event.type == :private_message
      user = @users[event.to]
      if user && @connections[user.id]
        connections = [@connections[user]]
      else
        connections = []
      end
    else # unfollow
      follower = @users[event.from]
      connections = []
      user = @users[event.to]
      if user && follower
        user.remove_follower follower if user
      end
    end
    connections.each { |e| e.puts event.payload }
  end

  def fetch
    payload = nil
    @queue.synchronize do
      @queue_cond.wait_while { @queue.empty? }
      payload = @queue.pop
    end
    payload
  end

end
