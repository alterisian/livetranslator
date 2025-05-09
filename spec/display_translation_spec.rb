require 'rspec'
require_relative '../display_translation'

RSpec.describe DisplayTranslation do
  subject(:display) { described_class.new }

  let(:callback) { ->(result) {} }

  before do
    allow(callback).to receive(:call)
  end

  after do
    FileUtils.rm_f file_path
    FileUtils.rm_f file_path_ignored
  end

  it 'gets the latest English translation text' do
    File.write(file_path, file_contents)

    livetext = display.display_live_text

    # continue from HERE
    expect(livetext).to eq file_contents
  end

  it 'ignores non-English translation text' do
    File.write(file_path, file_contents)
    File.write(file_path_ignored, '')

    livetext = display.display_live_text

    # continue from HERE
    expect(livetext).to eq file_contents
  end

  it 'follows file system changes' do
    display.follow_live_text(&callback)

    # sleep to allow Listener to wake up
    sleep 0.5
    # expect streaming text to be translated
    File.write(file_path, file_contents)
    # sleep to allow Listener to wake up
    sleep 0.5

    expect(callback).to have_received(:call).with(file_contents)
  end

  # Helper methods to provide test data
  def file_path
    'live_text/live_text_EN.txt'
  end

  def file_path_ignored
    'live_text_FE.txt'
  end

  def file_contents
    'Some sentence in English'
  end
end
