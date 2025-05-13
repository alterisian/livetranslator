require 'rspec'
require 'openai'
require 'tempfile'
require_relative '../live_transcriber'

# from claude.ai: https://claude.ai/share/6326057b-da86-404c-9b7c-c84d33e1634c

RSpec.describe LiveTranscriber do
  let(:mock_temp_file) { Tempfile.new(segment_uri) }
  let(:mock_transcriber) { instance_double(SpanishTranscriber) }

  before do
    # Mock external dependencies
    allow(SpanishTranscriber).to receive(:new).and_return(mock_transcriber)
    allow(mock_transcriber).to receive(:process_file).and_return(sample_transcription)

    # Mock stream segment file
    allow(Dir).to receive(:exists?).with('live_audio').and_return(true)
    allow(File).to receive_messages(
      open: mock_temp_file,
      size: 2048
    )

    # Mock M3u8::Playlist
    allow(M3u8::Playlist).to receive(:read) do
      # Call for Stopping transcriber after first playlist was served
      transcriber.stop
      mock_playlist
    end
  end

  describe '#initialize' do
    it 'creates a new transcriber with the provided URL', :aggregate_failures do
      transcriber = described_class.new(stream_url)
      expect(transcriber.instance_variable_get(:@stream_url)).to eq(stream_url)
      expect(transcriber.instance_variable_get(:@running)).to be(false)
    end

    it 'initializes an empty transcriptions array' do
      transcriber = described_class.new(stream_url)
      expect(transcriber.instance_variable_get(:@transcriptions)).to eq([])
    end
  end

  describe '#start' do
    subject(:transcriber) { described_class.new(stream_url) }

    it 'sets running to true' do
      # Use the first HTTP request to stop processing and check the @running flag
      allow(Net::HTTP).to receive(:get_response) do
        expect(transcriber.instance_variable_get('@running')).to be true
        transcriber.stop
      end
      transcriber.start
    end
  end

  describe '#start with stream_url' do
    subject(:transcriber) { described_class.new(stream_url) }

    before do
      mock_net_http
    end

    it 'processes the stream from URL' do
      transcriber.start
      expect(Net::HTTP).to have_received(:get_response).with(URI(stream_url))
    end

    it 'adds a transcription to the transcriptions array', :aggregate_failures do
      transcriber.start
      expect(transcriber.instance_variable_get(:@transcriptions).size).to eq(1)
      expect(transcriber.instance_variable_get(:@transcriptions).first[:text]).to eq(sample_transcription)
    end
  end

  describe '#start without stream URL' do
    subject(:transcriber) { described_class.new }

    let(:mock_listener) { instance_double(Listen::Listener) }

    before do
      allow(Listen).to receive(:to).and_return(mock_listener)
      allow(mock_listener).to receive(:start) do
        transcriber.stop
      end
    end

    it 'listens to local filesystem changes' do
      transcriber.start
      expect(mock_listener).to have_received(:start)
    end
  end

  describe '#on_translaction' do
    subject(:transcriber) { described_class.new(stream_url) }

    before do
      mock_net_http
    end

    it 'calls the provided block when a transcription is completed', :aggregate_failures do
      test_result = nil
      transcriber.on_transcription { |result| test_result = result }

      transcriber.start
      expect(test_result[:text]).to eq(sample_transcription)
    end
  end

  describe '#stop' do
    let(:transcriber) { described_class.new(stream_url) }

    it 'sets running to false' do
      transcriber.instance_variable_set(:@running, true)
      transcriber.stop
      expect(transcriber.instance_variable_get(:@running)).to be(false)
    end
  end

  # Helper methods to provide test data
  def stream_url
    'https://example.com/stream.m3u8'
  end

  def segment_uri
    'segment_1.aac'
  end

  def segment_url
    "https://example.com:443//#{segment_uri}"
  end

  def sample_m3u8
    <<~M3U8
      #EXTM3U
      #EXT-X-VERSION:3
      #EXT-X-TARGETDURATION:6
      #EXT-X-MEDIA-SEQUENCE:1
      #EXTINF:5.0,
      #{segment_uri}
    M3U8
  end

  def sample_segment_data
    'mock_audio_data'
  end

  def sample_transcription
    'Sample transcription'
  end

  def mock_playlist
    mock_playlist = instance_double(M3u8::Playlist)
    mock_segment = instance_double(M3u8::SegmentItem, segment: segment_uri)
    allow(mock_playlist).to receive(:items).and_return([mock_segment])
    allow(mock_segment).to receive(:is_a?).with(M3u8::SegmentItem).and_return(true)
    mock_playlist
  end

  def mock_net_http
    # Mock valid HTTP/1.0 200 OK URLs with fake response body
    {
      stream_url => sample_m3u8,
      segment_url => sample_segment_data
    }.each do |uri, body|
      response = Net::HTTPSuccess.new(1.0, '200', 'OK')
      allow(Net::HTTP).to receive(:get_response).with(URI(uri)).and_return(response)
      allow(response).to receive(:body).and_return(body)
    end
  end
end
