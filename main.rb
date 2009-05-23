require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'

DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/irclog.sqlite3"))
config = YAML.load(open('scribe.yml').read)

class LogEntry
  include DataMapper::Resource
  
  property :id, Integer, :serial => true  #primary serial key
  property :nick, Text, :nullable => false #cannot be null
  property :userhost, Text, :nullable => false #cannot be null
  property :channel, Text, :nullable => false #cannot be null
  property :message, Text, :nullable => false #cannot be null
  property :created_at, DateTime
  property :updated_at, DateTime
end

DataMapper.auto_upgrade!

# new
get '/' do
  haml :index
end

# channel
get '/channel/:channel' do
  @messages = LogEntry.all(:channel => "##{params[:channel]}")
  haml :channel
end

# create
post '/log' do
  @log_entry = LogEntry.new(:nick => params[:nick],
                            :userhost => params[:userhost],
                            :channel => params[:channel],
                            :message => params[:message])

  if (params[:secret] == config['secret']) and @log_entry.save
    "Saved log entry"
  else
    redirect "/"
  end
end

# show
get "/:id" do
  @log_entry = LogEntry.get(params[:id])
  if @log_entry
    haml :show
  else
    redirect '/'
  end
end
