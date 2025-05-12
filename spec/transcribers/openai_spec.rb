require 'faraday'
require 'tempfile'
require_relative '../../transcribers/openai'

RSpec.describe TranscriberOpenAI do
  let(:openai_double) { instance_double(OpenAI::Client) }
  let(:audio_double) { instance_double(OpenAI::Audio) }

  let(:mock_translated_text) { 'Translated text' }
  let(:mock_transscribe_response) { { 'text' => 'Transcribed text' } }
  let(:mock_chat_response) { { 'choices' => [{ 'message' => { 'content' => mock_translated_text } }] } }
  let(:transcriber) { described_class.new(Logger.new($stdout), 'fake openai key') }
  let(:mp4_file) { Tempfile.new('mp4') }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(openai_double)
    allow(openai_double).to receive(:audio).and_return(audio_double)

    mp4_file.write('fake mp4 data')
  end

  after do
    mp4_file.unlink
  end

  it 'Converts transcribes audio file to text' do
    expect(audio_double).to receive(:transcribe).and_return(mock_transscribe_response)

    expect(transcriber.transcribe_audio(mp4_file.path)).to eq(mock_transscribe_response)
  end

  it 'Translates text' do
    expect(openai_double).to receive(:chat).and_return(mock_chat_response)

    expect(transcriber.translate_text('foreign language text')).to eq(mock_translated_text)
  end

  it 'Retries on Server Error 500' do
    # First API call raises ServerError, Second call receives a response
    api_responses = [:raise, mock_transscribe_response]

    expect(audio_double).to receive(:transcribe).exactly(2).times do
      response = api_responses.shift
      response == :raise ? raise(Faraday::ServerError, 'Server Error') : response
    end

    stub_const('TranscriberOpenAI::RETRY_DELAY', 0.002) # Set delay to 2ms for faster test
    expect(transcriber.transcribe_audio(mp4_file.path)).to eq(mock_transscribe_response)
  end
end
