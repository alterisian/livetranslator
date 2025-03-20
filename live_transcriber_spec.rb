# spec/live_transcriber_spec.rb
require 'rspec'
require_relative '../live_transcriber'

RSpec.describe LiveTranscriber do
  describe '#initialize' do
    it 'sets up logger and OpenAI client' do
      expect(subject).to have_a(:logger)
      expect(subject).to have_a(:client)
    end

    it 'raises exception if no OpenAI API key is provided' do
      allow(ENV['OPENAI_API_KEY']).not_to be_set
      expect { subject.new }.to raise_error(Exception)
    end
  end

  describe '#start' do
    let!(:stream_url) { 'https://example.com/live_stream.m3u8' }
    let!(:subject) { LiveTranscriber.new(stream_url) }

    it 'starts transcription from the given stream URL' do
      expect(subject).to receive(:process_stream)
      subject.start
    end

    it 'logs info message when starting transcription' do
      allow(STDOUT).to receive(:puts)
      expect(STDOUT).to receive(:puts, "Starting transcription from: #{stream_url}")
      subject.start
    end
  end

  describe '#stop' do
    let!(:subject) { LiveTranscriber.new('https://example.com/live_stream.m3u8') }

    it 'sets running flag to false' do
      expect(subject.running?).to be(false)
      subject.stop
      expect(subject.running?).to be(false)
    end
  end

  describe '#on_transcription' do
    let!(:subject) { LiveTranscriber.new('https://example.com/live_stream.m3u8') }
    let!(&block) { ->(result) {} }

    it 'sets callback function' do
      expect(subject.callback).to eq(&block)
      subject.on_transcription(&block)
      expect(subject.callback).to eq(&block)
    end

    it 'calls callback function with result' do
      expect(subject.transcriptions).to be_empty
      block.call({ timestamp: Time.now.to_s, segment_url: 'https://example.com/segment1', text: 'Transcription 1' })
      expect(subject.transcriptions).to eq([{ timestamp: Time.now.to_s, segment_url: 'https://example.com/segment1', text: 'Transcription 1' }])
    end
  end

  describe '#process_stream' do
    let!(:subject) { LiveTranscriber.new('https://example.com/live_stream.m3u8') }

    it 'loops through playlist items' do
      allow(subject).to receive(:segment_url).twice
      expect(subject).to receive(:download_content)
      subject.process_stream
    end

    it 'logs info message when downloading content' do
      allow(STDOUT).to receive(:puts)
      subject.process_stream
    end

    it 'logs error message when failed to download' do
      allow(subject).to receive(:response).with(Net::HTTPSuccess).and_return(false)
      expect(STDOUT).to receive(:puts, "Failed to download: #{subject.hls_url}: 404")
      subject.process_stream
    end
  end

  describe '#download_content' do
    let!(:stream_url) { 'https://example.com/stream.m3u8' }
    let!(&block) { ->(content) {} }

    it 'downloads content from the given URL' do
      allow(subject).to receive(:response)
      expect(subject).to receive(:download_content, stream_url).with(Net::HTTPSuccess, content)
      block.call(content)
    end

    it 'logs info message when downloading content' do
      allow(STDOUT).to receive(:puts)
      subject.download_content(stream_url)
    end

    it 'logs error message when failed to download' do
      allow(subject).to receive(:response) { Net::HTTPSuccess }
      allow(subject).to receive(:response).with(Net::HTTPFailure)
      expect(STDOUT).to receive(:puts, "Failed to download: #{stream_url}: 404")
      subject.download_content(stream_url)
    end
  end

  describe '#process_chunk' do
    let!(&block) { ->(result) {} }
    let!(:temp_file) { Tempfile.new(['audio_segment', '.aac']) }

    it 'transcribes audio file' do
      allow(subject).to receive(:transcribe_audio)
      subject.process_chunk(temp_file.path, 'https://example.com/segment1')
    end

    it 'logs info message when transcribing audio' do
      expect(STDOUT).to receive(:puts, "Transcribe File: #{temp_file.path}")
      subject.process_chunk(temp_file.path, 'https://example.com/segment1')
    end

    it 'returns result' do
      allow(subject).to receive(:transcribe_audio)
      temp_file.write('audio data')
      expect(subject.process_chunk(temp_file.path, 'https://example.com/segment1')).to eq({
        timestamp: Time.now.to_s,
        segment_url: 'https://example.com/segment1',
        text: 'Transcription 1'
      })
    end

    it 'closes and unlink temp file' do
      allow(subject).to receive(:transcribe_audio)
      expect(temp_file).to receive(:close)
      expect(temp_file).to receive(:unlink)
      subject.process_chunk(temp_file.path, 'https://example.com/segment1')
    end
  end

  describe '#transcribe_audio' do
    let!(&block) { ->(result) {} }

    it 'returns transcription result' do
      allow(subject).to receive(:transcribe_audio)
      expect(subject.transcribe_audio('path/to/audio/file')).to eq('Sample transcription')
    end
  end

  describe '#running?' do
    let!(:subject) { LiveTranscriber.new('https://example.com/live_stream.m3u8') }

    it 'returns false when stopped' do
      subject.stop
      expect(subject.running?).to be(false)
    end

    it 'returns true when started' do
      subject.start
      expect(subject.running?).to be(true)
    end
  end

  describe '#transcriptions' do
    let!(:subject) { LiveTranscriber.new('https://example.com/live_stream.m3u8') }

    it 'stores transcriptions in an array' do
      allow(subject).to receive(:on_transcription)
      expect(subject.transcriptions).to be_empty
      subject.on_transcription { |result| {} }
      expect(subject.transcriptions).to eq([{ timestamp: Time.now.to_s, segment_url: 'https://example.com/segment1', text: 'Transcription 1' }])
    end

    it 'returns empty array when no transcriptions are present' do
      allow(subject).to receive(:on_transcription)
      expect(subject.transcriptions).to eq([{ timestamp: Time.now.to_s, segment_url: 'https://example.com/segment1', text: 'Transcription 1' }])
      subject.on_transcription { |result| {} }
      expect(subject.transcriptions).to be_empty
    end
  end
end