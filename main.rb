require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'
require 'haml'
require 'cfruntime'

if CFRuntime::CloudApp.running_in_cloud?
  @service_props = CFRuntime::CloudApp.service_props 'mysql'
  DataMapper.setup(:default, "mysql://#{@service_props[:username]}:#{@service_props[:password]}@#{@service_props[:host]}:#{@service_props[:port]}/#{@service_props[:database]}")
else
  DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/scribe.sqlite3"))
end

class Message
  include DataMapper::Resource

  property :id, Serial  #primary serial key
  property :nick, Text, :required => true #cannot be null
  property :userhost, Text, :required => true #cannot be null
  property :channel, Text, :required => true #cannot be null
  property :message, Text, :required => true #cannot be null
  property :created_at, DateTime
  property :updated_at, DateTime
end

class ConfigurationStore
  include DataMapper::Resource

  property :id, Serial  #primary serial key
  property :name, Text, :required => true #cannot be null
  property :data, Text, :required => true #cannot be null
end

DataMapper.auto_upgrade!

set :haml, {:format => :html5}

before do
  @secret = ConfigurationStore.first(:name => 'secret')

  unless @secret or request.path_info =~ /^\/secret/
    redirect '/secret'
  end
end

# index
get '/' do
  @channels = repository(:default).adapter.select('SELECT DISTINCT channel FROM messages ORDER BY channel')
  haml :index
end

# manage secret
get '/secret' do
  haml :secret
end

post '/secret' do
  secret_saved = false

  if params[:new]
    if @secret
      if (params[:old] == @secret.data)
        secret_saved = @secret.update_attributes(:data => params[:new])
      end
    else
      @secret = ConfigurationStore.new(:name => 'secret', :data => params[:new])
      secret_saved = @secret.save
    end
  end

  if secret_saved
    haml :secret_saved
  else
    redirect '/secret'
  end
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

# search
get '/search' do
  @messages = Message.all(:message.like => "%#{params[:q]}%")
  haml :search
end

# create
post '/log' do
  @message = Message.new(:nick => params[:nick],
                         :userhost => params[:userhost],
                         :channel => params[:channel],
                         :message => params[:message])

  if (params[:secret] == @secret.data) and @message.save
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
