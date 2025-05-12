# Usage: Run transcriber
# transcriber = SpanishTranscriber.new
# transcriber.transcribe_pending_files

require 'fileutils'
require 'logger'

require './transcribers/openai'

class SpanishTranscriber
  SUPPORTED_AUDIO_FORMATS = %w[mp3 ogg wav mp4 aac].freeze

<<<<<<< HEAD
  def initialize(event_name: '', translate_audio: true)
    @logger = Logger.new(STDOUT) # TODO - Change to file - Can we do this on a project basis.
    @logger.level = Logger::DEBUG
    @event_name = event_name.empty? ? '' : "#{event_name}_"
    @audio_dir = "events/#{@event_name}audio"
    @text_dir = "events/#{@event_name}text"    
=======
  def initialize(project_name: '', translate_audio: true, logger: nil)
    if logger.instance_of?(Logger)
      @logger = logger
    else
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::DEBUG
    end

    @project_name = project_name.empty? ? '' : "#{project_name}_"
    @audio_dir = "#{@project_name}audio"
    @text_dir = "#{@project_name}text"
>>>>>>> 37f43c531e869aa0e20fb7cf2bdb5b1ac7f18eb7
    @translate_audio = translate_audio

    @openapikey = ENV['OPENAI_API_KEY']
    if @openapikey && !@openapikey.empty?
      @logger.info 'OpenAI API key set'
      @transcriber = TranscriberOpenAI.new(@logger, @openapikey)
    else
      raise Exception.new 'Please place your OpenAI API key in the environment at OPENAI_API_KEY'
    end

    FileUtils.mkdir_p(@audio_dir)
    FileUtils.mkdir_p(@text_dir)
  end

  def transcribe_pending_files
    @logger.info("Scanning #{@audio_dir} for audio files...")
    audio_files = Dir.glob(File.join(@audio_dir, '*')).select { |f| valid_audio_file?(f) }

    if audio_files.empty?
      @logger.warn('No audio files found!')
      return
    else
      @logger.info("We have #{audio_files.count} audio files to transcribe.")
    end

    audio_files.each do |file|
      @logger.info("Starting processing #{file} audio files to transcribe.")
      process_file(file)
    end
  end

  def valid_audio_file?(file)
    ext = File.extname(file).downcase.delete_prefix('.')
    if SUPPORTED_AUDIO_FORMATS.include?(ext)
      true
    else
      @logger.warn("Skipping unsupported file format: #{file}")
      false
    end
  end

  def process_file(file)
    ext = File.extname(file).downcase
    base_name = File.basename(file, ext)
    spanish_file = File.join(@text_dir, "#{base_name}_ES.txt")
    english_file = File.join(@text_dir, "#{base_name}_EN.txt")

    if File.exist?(english_file) && File.exist?(spanish_file)
      @logger.info("Skipping #{file}, already transcribed and translated.")
      return
    end

    file = convert_mp4_to_mp3(file) if ext == '.mp4'
    file = convert_aac_to_wav(file) if ext == '.aac'

    return unless file # Skip if conversion failed

    transcribe_then_translate(file, spanish_file, english_file)
  end

  private

  def convert_mp4_to_mp3(mp4_file)
    mp3_file = mp4_file.sub(/\.mp4$/, '.mp3')
    return mp3_file if File.exist?(mp3_file) # Already converted

    @logger.info("Converting #{mp4_file} to MP3...")
    result = system("ffmpeg -i '#{mp4_file}' -q:a 3 '#{mp3_file}' 2>/dev/null")

    if result
      @logger.info("Successfully converted to #{mp3_file}")
      mp3_file
    else
      @logger.error("Failed to convert #{mp4_file} to MP3. Is ffmpeg installed?")
      nil
    end
  end

  def convert_aac_to_wav(input_file)
    output_file = input_file.sub(/\.aac$/, '.wav')
    begin
      # Check if ffmpeg is installed
      ffmpeg_installed = system("which ffmpeg > /dev/null 2>&1")

      unless ffmpeg_installed
        raise "FFmpeg not found. Consider extending SpanishTranscriber.convert_aac_to_wav to use a web API for conversion since local ffmpeg is unavailable."
      end

      # Use ffmpeg to convert AAC to WAV
      result = system("ffmpeg -i '#{input_file}' -acodec pcm_s16le -ar 44100 '#{output_file}' 2>/dev/null")

      unless result
        raise "FFmpeg conversion failed for #{input_file}"
      end
      @logger.info("Conversion successful: #{output_file}")
      output_file
    rescue => e
      @logger.error("Conversion failed: #{e.message}")
      nil
    end
  end

  def transcribe_then_translate(file, spanish_file, english_file)
    begin
      transcription = transcribe_audio(file)
    rescue StandardError => err
      log_generic_error(err, 'text', 'translation')
    end

    return unless transcription

    # Save Spanish transcription
    File.write(spanish_file, transcription)
    @logger.info("Saved Spanish transcription to #{spanish_file}")

    if @translate_audio && !File.exist?(english_file)
      translation = @transcriber.translate_text(transcription)
      @logger.info("Translation: #{translation}")
      return unless translation
      File.write(english_file, translation)
      @logger.info("Saved English translation to #{english_file}")
    end
  end

  def file_properties(file_path)
    {
      size_bytes: File.size(file_path),
      created_at: File.ctime(file_path),
      path: file_path,
      filename: File.basename(file_path)
    }
  end

  def transcribe_audio(file)
    @logger.info("Transcribing #{file}...")
    properties = file_properties(file)
    @logger.info("File properties: #{properties.inspect}")

    @transcriber.transcribe_audio(file)
  end

  def log_generic_error(error, item, action)
    @logger.error("Unexpected error during #{action} for #{item}: #{error.class} - #{error.message}")
    @logger.debug(error.backtrace.join("\n"))
  end
end

if __FILE__ == $PROGRAM_NAME
  # Run transcriber
  transcriber = SpanishTranscriber.new
  transcriber.transcribe_pending_files
end
