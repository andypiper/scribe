#!/usr/local/bin/ruby

require 'rubygems'
require 'net/http'
require 'uri'
require 'isaac'

config = YAML.load(open('scribe.yml').read)

configure do |c|
  c.realname = config['realname']
  c.nick    = config['nick']
  c.server  = config['server']
  c.port    = config['port']
end

on :connect do
  config['channels'].each do |channel| 
    join channel
  end
end

on :channel, /.*/ do
  Net::HTTP.post_form(URI.parse('http://localhost:4567/log'),
                      {
                        :secret => config['secret'],
                        :nick => nick,
                        :userhost => userhost,
                        :channel => channel,
                        :message => message
                      }
                     )

  puts "#{channel}: #{nick}: #{message}"
end
