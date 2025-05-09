module AudioFile
  # Audio File Format Conversions
  class Converter
    def initialize(logger)
      @logger = logger
    end

    def convert_mp4_to_mp3(mp4_file)
      mp3_file = mp4_file.path.sub(/\.mp4$/, '.mp3')
      convert_format(mp4_file, mp3_file, "ffmpeg -i '#{mp4_file}' -q:a 3 '#{mp3_file}' 2>/dev/null")
    end

    def convert_aac_to_wav(input_file)
      out = input_file.path.sub(/\.aac$/, '.wav')
      convert_format(input_file, out,
                     "ffmpeg -i '#{input_file.path}' -acodec pcm_s16le -ar 44100 '#{out}' 2>/dev/null")
    end

    private

    def convert_format(input_file, output_path, cmd)
      return File.new output_path if ::File.exist?(output_path) # Already converted

      output_file = File.new output_path

      @logger.info("Converting #{input_file.path} to #{output_file.ext[1..].upcase}...")
      result = ffmpeg_convert(cmd)
      raise ConversionError, "FFmpeg conversion failed for #{input_file.path}" unless result

      @logger.info("Conversion successful: #{output_path}")
      output_file
    end

    def ffmpeg_convert(cmd)
      ffmpeg_installed?

      # Use ffmpeg to convert AAC to WAV
      Kernel.system(cmd)
    end

    def ffmpeg_installed?
      return true if Kernel.system('which ffmpeg > /dev/null 2>&1')

      raise ConversionError,
            'FFmpeg not found. Consider extending SpanishTranscriber.convert_aac_to_wav to use a web' \
            'API for conversion since local ffmpeg is unavailable.'
    end
  end

  class ConversionError < StandardError
  end
end
