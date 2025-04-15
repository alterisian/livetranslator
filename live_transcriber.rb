# Quick run instructions, export OPENAI_API_KEY=""
# run: start_rtve_translation.rb

require 'net/http'
require 'uri'

require 'json'
require 'fileutils'
require 'logger'
require 'time'

require 'm3u8'
require 'openai'

require './spanish_transcriber'

class LiveTranscriber  

  def initialize(stream_url, event_id: 'live_')
    @logger = Logger.new(STDOUT) # TODO - Change to file - Can we do this on a project basis.
    @logger.level = Logger::INFO

    @openapikey = ENV["OPENAI_API_KEY"]
    if @openapikey
      @logger.info "OpenAI API key read"
      @client = OpenAI::Client.new(access_token: @openapikey)
    else
      raise Exception.new "Please place your OpenAI API key in the environment at OPENAI_API_KEY"
    end

    @stream_url = stream_url
    if @stream_url
      @logger.info "Stream URL read: #{@stream_url}"
    end

    @event_id = event_id
    if @event_id
      @logger.info("Event ID read: #{@event_id}")
    end

    @running = false
    @segment_buffer = []
    @transcriptions = []
    @callback = nil
  end

  def start
    @running = true
    @logger.info("Starting transcription from: #{@stream_url}")
    
    begin
      obs_stream = false
      if obs_stream 
        process_obs_stream  
      else
        process_stream 
      end
    rescue => err
    # rescue Faraday::TooManyRequestsError => err, thrown when out of OpenAI credits
      @logger.error("Error: #{err.message}")
      @logger.error(err.backtrace.join("\n"))
    end
  end

  def stop
    @running = false
  end
  
  def on_transcription(&block)
    @callback = block
  end

  private

  def process_obs_stream
    base_uri = URI(@stream_url)
    base_url = "#{base_uri.scheme}://#{base_uri.host}#{File.dirname(base_uri.path)}"
    
    while @running
      playlist_content = download_content(@stream_url)
      @logger.info "Playlist Content: #{playlist_content}"
      
      playlist = M3u8::Playlist.read(playlist_content)
      @logger.info "Playlist: #{playlist}"
      
      segments = playlist.items.select { |item| item.is_a?(M3u8::SegmentItem) }
      
      segments.each do |segment|
        break unless @running
        
        segment_url = segment.segment.start_with?('http') ? 
                      segment.segment : 
                      "#{base_url}/#{segment.segment}"
        @logger.info "Segment: #{segment_url}"

        next if @segment_buffer.include?(segment_url)
        
        @segment_buffer << segment_url
        @segment_buffer.shift if @segment_buffer.size > 100
        
        segment_data = download_content(segment_url)
        
        if segment_data && !segment_data.empty?
          process_obs_chunk(segment_data, segment_url)
        end
      end
      
      sleep 2 # Arbituary.
    end
  end

  def process_stream
    base_uri = URI(@stream_url)
    base_url = "#{base_uri.scheme}://#{base_uri.host}#{File.dirname(base_uri.path)}"
    
    while @running
      playlist_content = download_content(@stream_url)
      @logger.info "Playlist Content: #{playlist_content}"
      
      playlist = M3u8::Playlist.read(playlist_content)
      @logger.info "Playlist: #{playlist}"
      
      segments = playlist.items.select { |item| item.is_a?(M3u8::SegmentItem) }
      
      segments.each do |segment|
        break unless @running
        
        segment_url = segment.segment.start_with?('http') ? 
                      segment.segment : 
                      "#{base_url}/#{segment.segment}"
        @logger.info "Segment: #{segment_url}"

        next if @segment_buffer.include?(segment_url)
        
        @segment_buffer << segment_url
        @segment_buffer.shift if @segment_buffer.size > 100
        
        segment_data = download_content(segment_url)
        
        if segment_data && !segment_data.empty?
          process_chunk(segment_data, segment_url)
        end
      end
      
      sleep 2 # seems a bit arbitary
    end
  end

  def download_content(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    
    if response.is_a?(Net::HTTPSuccess)
      response.body
    else
      @logger.error("Failed to download: #{url}: #{response.code}")
      nil
    end
  end

  def process_chunk(audio_data, segment_url)
    event_audio_path_file="events/#{@event_id}_audio"
    FileUtils.mkdir_p(event_audio_path_file) unless Dir.exist?(event_audio_path_file)
    temp_file = File.open(File.join(event_audio_path_file, "audio_segment_#{Time.now.to_i}.aac"), 'wb')

    begin
      temp_file.binmode
      temp_file.write(audio_data)
      temp_file.flush
      temp_file.rewind
      
      unless File.exist?(temp_file.path) && File.size(temp_file.path) > 1024
        @logger.error("Audio file missing or too small: #{temp_file.path}")
        raise "Failed to save audio file: #{temp_file.path} (size: #{File.size(temp_file.path) rescue 'unknown'})"
      else
        @logger.info("chunk saved at: #{temp_file.path}, size: #{File.size(temp_file.path)}")
      end

      transcription = transcribe_audio(temp_file.path)      
      if transcription.nil? 
        @logger.info("Is nil")
        return
      end
      if transcription.is_a? Array
        @logger.info("Is array, not string: #{transcription}")
        return
      end
      if transcription.strip.empty?
        @logger.info("Empty string")
        return
      end
      
      timestamp = Time.now.strftime("%H:%M:%S")
      @logger.info("#{timestamp} | Transcription: #{transcription}")
      
      result = {
        timestamp: timestamp,
        segment_url: segment_url,
        text: transcription
      }
      
      @transcriptions << result
      @callback.call(result) if @callback
      
      return result
    ensure
      temp_file.close
      File.unlink(temp_file.path) rescue nil  # Delete the file, ignore errors if it fails
    end
  end

  def process_obs_chunk(audio_data, segment_url)
    FileUtils.mkdir_p('live_audio') unless Dir.exist?('live_audio')
    audio_file_path = File.join('live_audio', "audio_segment_#{Time.now.to_i}.aac")
    
    # Save audio data to a temporary file
    File.open(audio_file_path, 'wb') do |file|
      file.binmode
      file.write(audio_data)
    end

    # Transcribe audio if needed
    transcription = transcribe_audio(audio_file_path)
    if transcription.nil? 
      @logger.info("Is nil")
      return
    end
    if transcription.is_a? Array
      @logger.info("Is array, not string: #{transcription}")
      return
    end
    if transcription.strip.empty?
      @logger.info("Empty string")
      return
    end
    
    timestamp = Time.now.strftime("%H:%M:%S")
    @logger.info("#{timestamp} | Transcription: #{transcription}")
    
    result = {
      timestamp: timestamp,
      segment_url: segment_url,
      text: transcription
    }
    
    @transcriptions << result
    @callback.call(result) if @callback
    
    return result
  end

  def transcribe_audio(audio_file_path)
    @logger.info "Transcribe File: #{audio_file_path}"
    transcription = SpanishTranscriber.new(event_name: @event_id).transcribe_pending_files
    @logger.info "Transcription: #{transcription}"

    transcription
  end

end