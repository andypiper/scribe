#!/usr/local/bin/ruby

require "socket"
require 'net/http'
require 'uri'

# Don't allow use of "tainted" data by potentially dangerous operations
$SAFE=1

# The irc class, which talks to the server and holds the main event loop
class IRC
  def initialize(server, port, nick, channels)
    @server = server
    @port = port
    @nick = nick
    @channels = channels
  end

  def send(s)
    # Send a message to the irc server and print it to the screen
    puts "--> #{s}"
    @irc.send "#{s}\n", 0 
  end

  def msg(recipient, message)
    send "PRIVMSG #{recipient} :#{message}"
  end

  def connect()
    # Connect to the IRC server
    @irc = TCPSocket.open(@server, @port)
    send "USER blah blah blah :blah blah"
    send "NICK #{@nick}"

    if @channels.is_a?(Array)
      @channels.each do |channel|
        send "JOIN #{channel}"
      end
    else
      send "JOIN #{@channels}"
    end
  end

  def evaluate(s)
    # Make sure we have a valid expression (for security reasons), and
    # evaluate it if we do, otherwise return an error message
    if s =~ /^[-+*\/\d\s\eE.()]*$/ then
      begin
        s.untaint
        return eval(s).to_s
      rescue Exception => detail
        puts detail.message()
      end
    end
    return "Error"
  end

  def handle_server_input(s)
    # This isn't at all efficient, but it shows what we can do with Ruby
    # (Dave Thomas calls this construct "a multiway if on steroids")
    case s.strip
    when /^PING :(.+)$/i
      puts "[ Server ping ]"
      send "PONG :#{$1}"
    when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]PING (.+)[\001]$/i
      puts "[ CTCP PING from #{$1}!#{$2}@#{$3} ]"
      send "NOTICE #{$1} :\001PING #{$4}\001"
    when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]VERSION[\001]$/i
      puts "[ CTCP VERSION from #{$1}!#{$2}@#{$3} ]"
      send "NOTICE #{$1} :\001VERSION Ruby-irc v0.042\001"
    when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:EVAL (.+)$/i
      puts "[ EVAL #{$5} from #{$1}!#{$2}@#{$3} ]"
      send "PRIVMSG #{(($4==@nick)?$1:$4)} :#{evaluate($5)}"
    when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:(.+)$/i
      puts "[ MSG (#{$4}) #{$5} from #{$1}!#{$2}@#{$3} ]"

      Net::HTTP.post_form(URI.parse('http://localhost:4567/log'),
                          {
                            :secret => 'ct_secret',
                            :nick => $1,
                            :user => $2,
                            :host => $3,
                            :recipient => $4,
                            :message => $5
                          }
                         )
    else
      puts s
    end
  end

  def main_loop()
    # Just keep on truckin' until we disconnect
    while true
      ready = select([@irc, $stdin], nil, nil, nil)
      next if !ready
      for s in ready[0]
        if s == $stdin then
          return if $stdin.eof
          s = $stdin.gets
          send s
        elsif s == @irc then
          return if @irc.eof
          s = @irc.gets
          handle_server_input(s)
        end
      end
    end
  end
end

# The main program
# If we get an exception, then print it out and keep going (we do NOT want
# to disconnect unexpectedly!)
irc = IRC.new('irc.freenode.net', 6667, 'ct_scribe', ['#commonthread', '#ruby-lang'])
irc.connect()
begin
  irc.main_loop()
rescue Interrupt
rescue Exception => detail
  puts detail.message()
  print detail.backtrace.join("\n")
  retry
end
