require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'

DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/scribe.sqlite3"))

class Message
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

config = YAML.load(open('scribe.yml').read)

# new
get '/' do
  haml :index
end

# channel
get '/channel/:channel' do
  @messages = Message.all(:channel => "##{params[:channel]}")
  haml :channel
end

# nick
get '/nick/:nick' do
  @messages = Message.all(:nick => "#{params[:nick]}")
  haml :nick
end

# create
post '/log' do
  @message = Message.new(:nick => params[:nick],
                         :userhost => params[:userhost],
                         :channel => params[:channel],
                         :message => params[:message])

  if (params[:secret] == config['secret']) and @message.save
    "Saved log entry"
  else
    redirect "/"
  end
end

# show
get "/:id" do
  @message = Message.get(params[:id])
  if @message
    haml :show
  else
    redirect '/'
  end
end
