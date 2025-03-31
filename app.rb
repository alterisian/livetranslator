# app.rb
require 'sinatra'

get '/' do
  # Changes to the text here require a restart of the Sinatra server (puma)
  @en_text = 'To work in product, it is necessary to have a multidisciplinary team with various profiles, which ensures that new functionalities are delivered with each development.'
  
  erb :index
end

# Question: What end points are needed?
# Ideas:
# /start with stream_url - this could be the root. Any additional options? i.e. 4 seconds/EN and/or ES output?
# /stop with stream_id_or_url or just stream_url
# /display/stream_id_or_url - is it possible without a db? Can we avoid a db initially?
# /transcrition/stream_id_or_url - gives all the text for the recent stream transcription/translation

# Question: What is the most basic needed vs actually nice. i.e. we don't NEED a great font, but will make it more readable.
# Question: Do we just display the translation? Or original transcription too? Is it a complication to do both i.e. reduce usability? How do we test that? 2 events? 1 with/1 without.

