require 'faraday'
require 'tempfile'
require_relative '../lib/transcribers/openai'

RSpec.describe TranscriberOpenAI do
  let(:openai_double) { instance_double(OpenAI::Client) }
  let(:audio_double) { instance_double(OpenAI::Audio) }

  let(:transcriber) { described_class.new(Logger.new($stdout), 'fake openai key') }
  let(:mp4_file) { Tempfile.new('mp4') }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(openai_double)
    allow(openai_double).to receive(:audio).and_return(audio_double)

    stub_const('TranscriberOpenAI::RETRY_DELAY', 0.002) # Set delay to 2ms for faster test

    mp4_file.write('fake mp4 data')
  end

  after do
    mp4_file.unlink
  end

  it 'Converts transcribes audio file to text' do
    allow(audio_double).to receive(:transcribe).and_return(mock_transscribe_response)

    expect(transcriber.transcribe_audio(mp4_file.path)).to eq(mock_transscribe_response)
  end

  it 'Translates text' do
    allow(openai_double).to receive(:chat).and_return(mock_chat_response)

    expect(transcriber.translate_text('foreign language text')).to eq(mock_translated_text)
  end

  it 'Retries on Server Error 500' do
    simulate_http_server_error subject: audio_double, method: :transcribe, response: mock_transscribe_response
    expect(transcriber.transcribe_audio(mp4_file.path)).to eq(mock_transscribe_response)
  end

  it 'Gives up on subsequent Server Error 500 responses' do
    simulate_http_server_error_give_up subject: audio_double, method: :transcribe, times: 5
    expect(transcriber.transcribe_audio(mp4_file.path)).to be_nil
  end

  # Helper methods to provide test data
  def mock_translated_text
    'Translated text'
  end

  def mock_transscribe_response
    { 'text' => 'Transcribed text' }
  end

  def mock_chat_response
    {
      'choices' => [{ 'message' => { 'content' => mock_translated_text } }]
    }
  end

  def simulate_http_server_error(subject:, method:, response:)
    # First API call raises ServerError, Second call receives a response
    api_responses = [:raise, response]

    allow(subject).to receive(method).twice do
      response = api_responses.shift
      response == :raise ? raise(Faraday::ServerError, 'Server Error') : response
    end
  end

  def simulate_http_server_error_give_up(subject:, method:, times:)
    # API call raises ServerError a number of times
    allow(subject).to receive(method).at_least(times).times do
      raise(Faraday::ServerError, 'Server Error')
    end
  end
end
