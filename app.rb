# This is a sinatra application: https://sinatrarb.com/intro.html
# Question: Do we just display the translation? Or original transcription too? Is it a complication to do both i.e. reduce usability? How do we test that? 2 events? 1 with/1 without.

require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'logger'

require './display_translation'

use Rack::MethodOverride      # Allows DELETE and PUT to work

configure :development do
  register Sinatra::Reloader
end

set :layout, :principal_layout
set :method_override, true      # Allows DELETE and PUT to work

logger = Logger.new('log/app.log') # Log to a specific file, rather than STDOUT
logger.level = Logger::INFO

before do
  cache_control :no_cache
  headers \
    "Pragma"   => "no-cache",
    "Expires" => "0"
end

get '/' do  
  @data = {
    en_text: 'To work in product, it is necessary to have a multidisciplinary team with various profiles, which ensures that new functionalities are delivered with each development.'
  }  
  @data.to_json

  logger.info("Received request for root path")
  erb :index
end

get '/update' do
  content_type :json  
  
  last_translated_text = DisplayTranslation.new.display_live_text

  logger.info("LAST: #{last_translated_text}")

  data = {
    en_text: last_translated_text
  }

  data.to_json
end

# GET /new - Displays a form to capture a new stream URL for translation
get '/new' do
  erb :new, layout: :principal_layout
end

# POST /create - Called from form in new, and displays event translation page and controls
post '/create' do
  @event_id = DisplayTranslation.new.create_event_directory
  # TODO - explore redirect to /events/id to display is index
  erb :create, layout: :principal_layout
end

# GET /event_id - shows the live translation for this event.
get '/:event_id' do
  @event_id = params[:event_id]
  logger.info("Displaying live translation for event ID: #{@event_id}")
  erb :show, layout: :principal_layout
end

# DELETE /event_id - stops the live translation for the event
# TODO - IM: Not currently detected from the from in create. 
delete '/:event_id' do
  @event_id = params[:event_id]
  # stop the translation for the given event_id
  logger.info("Stopping translation for event ID: #{@event_id}")  
  status 204 # No Content
end
