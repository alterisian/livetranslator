# Quick run instructions, export OPENAI_API_KEY=""
# run: live_transcriber.rb

require 'net/http'
require 'uri'

require 'json'
require 'fileutils'
require 'logger'
require 'time'

require 'm3u8'
require 'openai'
<<<<<<< HEAD

require './spanish_transcriber'

class LiveTranscriber  

  def initialize(stream_url, event_id: 'live_')
    @logger = Logger.new(STDOUT) # TODO - Change to file - Can we do this on a project basis.
=======
require 'uri'
require 'listen'
require 'logger'
require 'fileutils'
require 'json'
require 'time'

require './spanish_transcriber'

class LiveTranscriber
  def initialize(stream_url = nil)
    $stdout.sync = true
    @logger = Logger.new($stdout)
>>>>>>> 37f43c531e869aa0e20fb7cf2bdb5b1ac7f18eb7
    @logger.level = Logger::INFO
    @obs_stream = true
    @transcriber = SpanishTranscriber.new(project_name: 'live', logger: @logger)

    if stream_url
      @stream_url = stream_url
      @logger.info "Stream URL read: #{@stream_url}" if @stream_url
      @obs_stream = false
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

    begin
      if @obs_stream
        process_local_stream
      else
        process_stream_from_url
      end
    rescue StandardError => e
      @logger.error("Error: #{e.message}")
      @logger.error(e.backtrace.join("\n"))
    end
  end

  def stop
    @running = false
  end

  def on_transcription(&block)
    @callback = block
  end

  private

  def process_local_stream
    listener = Listen.to('live_audio', &file_change_callback)
    listener.start

    @logger.info('Listening for new files in live_audio/ directory')

    while @running
      sleep 2 # seems a bit arbitary
    end
  end

  def file_change_callback
    proc do |modified|
      modified.each do |file|
        next unless @transcriber.valid_audio_file?(file)

        @logger.info("New file detected: #{file}")
        handle_transcription(transcribe_audio(file), file)
      end
    end
  end

  def process_stream_from_url
    @logger.info("Starting transcription from: #{@stream_url}")

    base_uri = URI(@stream_url)
    base_url = "#{base_uri.scheme}://#{base_uri.host}:#{base_uri.port}#{File.dirname(base_uri.path)}"

    while @running
      playlist_content = download_content(@stream_url)
      @logger.info "Playlist Content: #{playlist_content}"

      playlist = M3u8::Playlist.read(playlist_content)
      @logger.info "Playlist: #{playlist}"

      process_playlist(playlist.items, base_url)

      break unless @running

      sleep 2 # seems a bit arbitary
    end
  end

  def process_playlist(playlist_items, base_url)
    segments = playlist_items.select { |item| item.is_a?(M3u8::SegmentItem) }
    segments.each do |segment|
      segment_url = (segment.segment.start_with?('http') ? segment.segment : "#{base_url}/#{segment.segment}")
      next if @segment_buffer.include?(segment_url)

      segment_data = download_segment(segment_url)
      process_chunk(segment_data, segment_url) if segment_data && !segment_data.empty?
    end
  end

  def download_segment(segment_uri)
    @logger.info "Segment: #{segment_uri}"

    @segment_buffer << segment_uri
    @segment_buffer.shift if @segment_buffer.size > 100

    download_content(segment_uri)
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

<<<<<<< HEAD
  def process_chunk(audio_data, segment_url)
    event_audio_path_file="events/#{@event_id}_audio"
    FileUtils.mkdir_p(event_audio_path_file) unless Dir.exist?(event_audio_path_file)
    temp_file = File.open(File.join(event_audio_path_file, "audio_segment_#{Time.now.to_i}.aac"), 'wb')

=======
  def process_chunk(audio_data, segment_uri)
    temp_file = File.open(File.join('live_audio', "audio_segment_#{Time.now.to_i}.aac"), 'wb').binmode
>>>>>>> 37f43c531e869aa0e20fb7cf2bdb5b1ac7f18eb7
    begin
      # Write and transcribe audio if needed
      write_audio_data(temp_file, audio_data)
      handle_transcription(transcribe_audio(temp_file.path), segment_uri)
    ensure
      temp_file.close
      begin
        File.unlink(temp_file.path)
      rescue StandardError
        nil # Delete the file, ignore errors if it fails
      end
    end
  end

  def write_audio_data(file, audio_data)
    file.write(audio_data)
    file.flush
    f_size = begin
      File.size(file.path)
    rescue StandardError
      StandardError 'unknown'
    end
    unless File.exist?(file.path) && f_size.is_a?(Integer) && f_size > 1024
      @logger.error("Audio file missing or too small: #{file.path}")
      raise "Failed to save audio file: #{file.path} (size: #{f_size})"
    end
    @logger.info("Chunk saved at: #{file.path}, size: #{f_size}")
  end

  def transcribe_audio(audio_file_path)
    @logger.info "Transcribe File: #{audio_file_path}"
<<<<<<< HEAD
    transcription = SpanishTranscriber.new(event_name: @event_id).transcribe_pending_files
=======
    transcription = @transcriber.process_file(audio_file_path)
>>>>>>> 37f43c531e869aa0e20fb7cf2bdb5b1ac7f18eb7
    @logger.info "Transcription: #{transcription}"

    transcription
  end

  def handle_transcription(transcription, segment_uri)
    if transcription.nil?
      @logger.info('Is nil')
    elsif transcription.is_a? Array
      @logger.info("Is array, not string: #{transcription}")
    elsif (transcription.is_a? String) && transcription.strip.empty?
      @logger.info('Empty string')
    else
      process_transcription(transcription, segment_uri)
    end
  end

  def process_transcription(transcription, segment_uri)
    timestamp = Time.now.strftime('%H:%M:%S')
    @logger.info("#{timestamp} | Transcription: #{transcription}")

    result = {
      timestamp: timestamp,
      segment_uri: segment_uri,
      text: transcription
    }

    @transcriptions << result
    @callback&.call(result)
  end
end

if __FILE__ == $PROGRAM_NAME
  lt = LiveTranscriber.new
  lt.start
end
