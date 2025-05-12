require 'openai'

class TranscriberOpenAI
  MAX_RETRIES = 3
  RETRY_DELAY = 2 # Initial delay in seconds, increases exponentially

  OPENAI_WHISPER_FILE_SIZE_LIMIT = 25_000_000 # 25 MB

  def initialize(logger, openapikey)
    @logger = logger
    @client = OpenAI::Client.new(access_token: openapikey)
  end

  def transcribe_audio(file)
    if File.size(file) > OPENAI_WHISPER_FILE_SIZE_LIMIT
      @logger.warn("Skipping file #{file} because it exceeds the 25MB file upload limit for OpenAI Whisper.")
      return nil
    end

    @logger.info("Transcribing #{file}...")

    retries = 0
    begin
      response = @client.audio.transcribe(
        parameters: {
          model: 'whisper-1',
          file: File.open(file, 'rb'),
          response_format: 'text'
        }
      )
      @logger.debug("Transcription response: #{response.inspect}")

      if response.nil? || response.empty?
        @logger.warn("No text transcribed for #{file}.")
        return nil
      end

      return response
    rescue Faraday::ServerError => e # HTTP 500
      if retries < MAX_RETRIES
        delay = RETRY_DELAY**(retries + 1)
        @logger.warn("Server error (500) during transcription of #{file}. Retrying in #{delay} seconds... (Attempt #{retries + 1}/#{MAX_RETRIES})")
        sleep(delay)
        retries += 1
        retry
      else
        @logger.error("Persistent server error (500) for #{file}. Skipping after #{MAX_RETRIES} retries.")
      end
    rescue Faraday::BadRequestError => e
      @logger.error("Bad request error during transcription: #{e.message}")
      @logger.error('This usually means the API rejected our request format')
    rescue Faraday::TooManyRequestsError => e
      log_api_error(e, file, 'transcription')
    rescue OpenAI::Error => e
      log_api_error(e, file, 'transcription')
    end
    nil
  end

  def translate_text(text)
    @logger.info('Translating text...')

    retries = 0
    begin
      response = @client.chat(
        parameters: {
          model: 'gpt-4',
          messages: [
            { role: 'system',
              content: 'You are a translator. Translate the following Spanish text to English, maintaining the original meaning and tone.' },
            { role: 'user', content: text }
          ]
        }
      )
      return response.dig('choices', 0, 'message', 'content')
    rescue Faraday::ServerError => e # HTTP 500
      if retries < MAX_RETRIES
        delay = RETRY_DELAY**(retries + 1)
        @logger.warn("Server error (500) during translation. Retrying in #{delay} seconds... (Attempt #{retries + 1}/#{MAX_RETRIES})")
        sleep(delay)
        retries += 1
        retry
      else
        @logger.error("Persistent server error (500) for translation. Skipping after #{MAX_RETRIES} retries.")
      end
    rescue Faraday::BadRequestError => e
      @logger.error("Bad request error during translation: #{e.message}")
      @logger.error('This usually means the API rejected our request format')
    rescue OpenAI::Error => e
    rescue Faraday::TooManyRequestsError => e
      log_api_error(e, 'text', 'translation')
    end

    nil
  end

  def log_api_error(error, item, action)
    @logger.error("API Error during #{action} for #{item}: #{error.message}")

    if error.response
      @logger.debug("Response Headers: #{error.response[:headers]}")
      @logger.debug("Response Status Code: #{error.response[:status]}")
      @logger.debug("Response Body: #{error.response[:body]}")
    end

    @logger.error('❌ Authentication issue: Check your OpenAI API key!') if error.message.include?('401')
    @logger.error('❌ Rate Limiting issue: Check your OpenAI API remaining credits') if error.message.include?('429')
  end
end
