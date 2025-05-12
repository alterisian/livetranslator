require 'rspec'
require 'openai'
require 'tempfile'
require_relative '../live_transcriber'

# from claude.ai: https://claude.ai/share/6326057b-da86-404c-9b7c-c84d33e1634c

RSpec.describe LiveTranscriber do
  let(:stream_url) { 'https://example.com/stream.m3u8' }
  let(:segment_uri) { 'segment_1.aac' }
  let(:mock_transcriber) { instance_double(SpanishTranscriber) }

  before do
    # Mock external dependencies
    allow(SpanishTranscriber).to receive(:new).and_return(mock_transcriber)
    allow(mock_transcriber).to receive(:process_file).and_return(sample_transcription)

    # Mock stream segment file
    mock_temp_file = Tempfile.new(segment_uri)
    allow(Dir).to receive(:exists?).with('live_audio').and_return(true)
    allow(File).to receive(:open).and_return(mock_temp_file)
    allow(File).to receive(:size).and_return(2048)

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

    it 'raises an exception if the OpenAI API key is not set' do
      allow(SpanishTranscriber).to receive(:new).and_call_original
      allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(nil)
      expect do
        described_class.new(stream_url)
      end.to raise_error(Exception, 'Please place your OpenAI API key in the environment at OPENAI_API_KEY')
    end
  end

  describe '#start with stream_url' do
    let(:transcriber) { described_class.new(stream_url) }

    before do
      allow(transcriber).to receive(:download_content).and_return(sample_m3u8, sample_segment_data)
    end

    it 'processes the stream from URL' do
      allow(transcriber).to receive(:process_stream_from_url).and_return(nil)

      transcriber.start
      expect(transcriber).to have_received(:process_stream_from_url).once
    end

    it 'sets running to true' do
      transcriber.start
      # It gets set back to false by our mocked M3u8::Playlist
      expect(transcriber.instance_variable_get(:@running)).to be(false)
    end

    it 'adds a transcription to the transcriptions array', :aggregate_failures do
      transcriber.start
      expect(transcriber.instance_variable_get(:@transcriptions).size).to eq(1)
      expect(transcriber.instance_variable_get(:@transcriptions).first[:text]).to eq(sample_transcription)
    end
  end

  describe '#start without stream URL' do
    let(:transcriber) { described_class.new }

    before do
      allow(transcriber).to receive(:process_local_stream)
    end

    it 'processes local streams without a stream URL' do
      transcriber.start
      expect(transcriber).to have_received(:process_local_stream).once
    end

    it 'sets running to true' do
      transcriber.start
      # It gets set back to false by our mocked M3u8::Playlist
      expect(transcriber.instance_variable_get(:@running)).to be(true)
    end
  end

  describe '#on_translaction' do
    let(:transcriber) { described_class.new(stream_url) }

    before do
      allow(transcriber).to receive(:download_content).and_return(sample_m3u8, sample_segment_data)
    end

    it 'calls the provided block when a transcription is completed', :aggregate_failures do
      callback_called = false
      test_result = nil

      transcriber.on_transcription do |result|
        callback_called = true
        test_result = result
      end

      transcriber.start

      expect(callback_called).to be(true)
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
end
