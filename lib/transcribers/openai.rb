require 'openai'

# This class handles the transcription and translation of audio files using OpenAI's Whisper API.
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
    safe_api_call("transcription of #{file}") { api_call_audio_transcribe(file) }
  end

  def translate_text(text)
    @logger.info('Translating text...')
    safe_api_call('translate text') { api_call_translate_text(text) }
  end

  private

  def safe_api_call(action, &)
    @last_api_call = action
    @last_api_response = nil
    api_call_with_retry(MAX_RETRIES, &)
    @last_api_response
  rescue Faraday::BadRequestError => e
    log_api_error(e, 'Bad Request', 'This usually means the API rejected our request format')
  rescue Faraday::TooManyRequestsError => e
    log_api_error(e, 'TooManyRequests')
  rescue OpenAI::Error => e
    log_api_error(e, 'OpenAI')
  end

  def api_call_with_retry(max_retries, &block)
    retries = 0
    begin
      handle_response yield block
    rescue Faraday::ServerError # HTTP 500
      if (retries += 1) < max_retries
        server_error_delay_and_retry(retries)
        retry
      end

      @logger.error("Persistent server error (500) for #{@last_api_call}. Skipping after #{max_retries} retries.")
    end
  end

  def api_call_audio_transcribe(file)
    @client.audio.transcribe(
      parameters: {
        model: 'whisper-1',
        file: File.open(file, 'rb'),
        response_format: 'text'
      }
    )
  end

  def api_call_translate_text(text)
    response = @client.chat(
      parameters: {
        model: 'gpt-4',
        messages: translate_text_roles(text)
      }
    )
    response.dig('choices', 0, 'message', 'content')
  end

  def translate_text_roles(text)
    [
      { role: 'system',
        content: 'You are a translator. Translate the following Spanish text to English, ' \
                 'maintaining the original meaning and tone.' },
      { role: 'user', content: text }
    ]
  end

  def handle_response(response)
    @logger.debug("OpenAI API response for #{@last_api_call}: #{response.inspect}")

    if response.nil? || response.empty?
      @logger.warn("No response for #{@last_api_call}.")
      return nil
    end

    @last_api_response = response
  end

  def server_error_delay_and_retry(retries)
    delay = RETRY_DELAY**retries
    @logger.warn(
      "Server error (500) during #{@last_api_call}. Retrying in #{delay} seconds... " \
      "(Attempt #{retries}/#{MAX_RETRIES})"
    )
    sleep(delay)
  end

  def log_api_error(error, reason, detail = nil)
    @logger.error("#{reason} Error during #{@last_api_call}: #{error.message}")
    @logger.error(detail) if detail
    error_response_debug(error)

    @logger.error('❌ Authentication issue: Check your OpenAI API key!') if error.message.include?('401')
    @logger.error('❌ Rate Limiting issue: Check your OpenAI API remaining credits') if error.message.include?('429')
  end

  def error_response_debug(error)
    return unless error.response

    @logger.debug("Response Headers: #{error.response[:headers]}")
    @logger.debug("Response Status Code: #{error.response[:status]}")
    @logger.debug("Response Body: #{error.response[:body]}")
  end
end
