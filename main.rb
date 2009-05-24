require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'

DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/irclog.sqlite3"))

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

class ConfigStore
  include DataMapper::Resource

  property :id, Integer, :serial => true  #primary serial key
  property :name, Text, :nullable => false #cannot be null
  property :data, Text, :nullable => false #cannot be null
end

DataMapper.auto_upgrade!

if config_item = ConfigStore.first(:name => 'scribe.yml')
  config = Yaml.load(config_item.data)
else
  config = YAML.load(open('scribe.yml').read)
end

# new
get '/' do
  haml :index
end

# channel
get '/channel/:channel' do
  @messages = Message.all(:channel => "##{params[:channel]}")
  haml :channel
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
