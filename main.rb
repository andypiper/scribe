require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'

DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/irclog.sqlite3"))

class LogEntry
  include DataMapper::Resource
  
  property :id, Integer, :serial => true  #primary serial key
  property :nick, Text, :nullable => false #cannot be null
  property :user, Text, :nullable => false #cannot be null
  property :host, Text, :nullable => false #cannot be null
  property :recipient, Text, :nullable => false #cannot be null
  property :message, Text, :nullable => false #cannot be null
  property :created_at, DateTime
  property :updated_at, DateTime
  
  # validates_present :nick, :user, :host, :recipient, :message
  # validates_length :body, :minimum => 1
end

DataMapper.auto_upgrade!

# new
get '/' do
  haml :index
end

# create

post '/log' do
  @log_entry = LogEntry.new(:nick => params[:nick],
                            :user => params[:user],
                            :host => params[:host],
                            :recipient => params[:recipient],
                            :message => params[:message])

  if (params[:secret] == 'ct_secret') and @log_entry.save
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
