require 'fileutils'
require 'logger'

require './lib/audio_file'
require './lib/audio_file/converter'
require './lib/transcribers/openai'

## Transcriber class, only transcribing Spanish-to-English currently
class SpanishTranscriber
  SUPPORTED_AUDIO_FORMATS = %w[mp3 ogg wav mp4 aac].freeze

  def initialize(project_name: nil, translate_audio: true, logger: nil)
    raise TranscriberError, "Provide a valid Logger instance: #{logger.inspect}" unless logger.is_a?(Logger)

    @logger = logger
    @translate_audio = translate_audio
    @audio_file_converter = nil

    project_init name: project_name
    transcriber
  end

  def transcribe_pending_files
    audio_files = self.audio_files
    if audio_files.empty?
      @logger.warn('No audio files found!')
    else
      @logger.info("We have #{audio_files.count} audio files to transcribe.")
      audio_files.each { |file| process_file(file) }
    end
  end

  def audio_files
    @logger.info("Scanning #{@audio_dir} for audio files...")
    Dir.glob(File.join(@audio_dir, '*')).select { |f| valid_audio_file?(f) }
  end

  def valid_audio_file?(file)
    if SUPPORTED_AUDIO_FORMATS.include?(AudioFile::File.new(file).format)
      true
    else
      @logger.warn("Skipping unsupported file format: #{file}")
      false
    end
  end

  def process_file(file_path)
    f = AudioFile::File.new file_path
    spanish_file = File.join(@text_dir, "#{f.base_name}_ES.txt")
    english_file = File.join(@text_dir, "#{f.base_name}_EN.txt")

    if File.exist?(english_file) && File.exist?(spanish_file)
      @logger.info("Skipping #{file}, already transcribed and translated.")
    else
      safe_process(f, spanish_file, english_file)
    end
  end

  private

  def project_init(name: nil)
    @project_name = name.nil? ? '' : "#{name}_"
    @audio_dir = "#{@project_name}audio"
    @text_dir = "#{@project_name}text"

    FileUtils.mkdir_p(@audio_dir)
    FileUtils.mkdir_p(@text_dir)
  end

  def safe_process(audio_file, spanish_file, english_file)
    transcribe_then_translate(audio_file_conversions(audio_file), spanish_file, english_file)
  rescue AudioFile::ConversionError => e
    log_generic_error(e, 'audio', 'conversion')
  rescue StandardError => e
    log_generic_error(e, 'text', 'translation')
  end

  def transcribe_then_translate(audio_file, spanish_file, english_file)
    transcription = transcribe_audio(audio_file)
    File.write(spanish_file, transcription)
    @logger.info("Saved Spanish transcription to #{spanish_file}")

    return unless @translate_audio && !File.exist?(english_file)

    translate(transcription, english_file)
  end

  def transcriber
    return @transcriber if @transcriber

    openapikey = ENV.fetch('OPENAI_API_KEY', nil)
    unless openapikey && !openapikey.empty?
      raise TranscriberError, 'Please place your OpenAI API key in the environment at OPENAI_API_KEY'
    end

    @logger.info 'OpenAI API key set'
    @transcriber = TranscriberOpenAI.new(@logger, openapikey)
  end

  def audio_file_conversions(file)
    case file.ext.downcase
    when '.mp4'
      audio_file_converter.convert_mp4_to_mp3(file)
    when '.aac'
      audio_file_converter.convert_aac_to_wav(file)
    else
      file
    end
  end

  def audio_file_converter
    @audio_file_converter ||= AudioFile::Converter.new @logger
  end

  def transcribe_audio(file)
    @logger.info("Transcribing #{file.path}...")
    @logger.info("File properties: #{file.properties.inspect}")

    @transcriber.transcribe_audio(file.path)
  end

  def translate(transcription, english_file)
    translation = @transcriber.translate_text(transcription)
    @logger.info("Translation: #{translation}")
    return unless translation

    File.write(english_file, translation)
    @logger.info("Saved English translation to #{english_file}")
  end

  def log_generic_error(error, item, action)
    @logger.error("Unexpected error during #{action} for #{item}: #{error.class} - #{error.message}")
    @logger.debug(error.backtrace.join("\n"))
  end
end

class TranscriberError < StandardError
end

if __FILE__ == $PROGRAM_NAME
  logger = Logger.new($stdout)
  logger.level = Logger::DEBUG

  # Run transcriber
  transcriber = SpanishTranscriber.new project_name: ARGV.shift, logger: logger
  transcriber.transcribe_pending_files
end
