# frozen_string_literal: true

require 'rspec'
require_relative '../display_translation'

RSpec.describe DisplayTranslation do
  # display
  it 'getting latest English(default) translation text' do    
    file_path = "live_text_EN.txt"
    File.delete(file_path) if File.exist?(file_path)
    
    display = described_class.new
    livetext = display.display_live_text
    
    # continue from HERE
    expect(livetext).not_to be_empty
    expect(livetext).to eq('This is the first time we have seen the father since he was admitted last February 14th.')
    
    # expect streaming text to be translated
    file = File.open(file_path, "w")
    if file
        file.write("Some sentence in English")
    end

    # define a spy
    
    callback = ->(result) { result } 

    expect(callback).to receive(:call).with("Some sentence in English")
    
    display.follow_live_text(&callback)

    # maybe sleep
    # create the file
  end

  it 'can convert a timestamp to Time' do
    filename = 'audio_segment_1741691051_EN.txt'
    decoded_time = DisplayTranslation.new.decode_time_from_filename(filename)
    expect(decoded_time.hour).to eq(12)
    expect(decoded_time.min).to eq(4)
    expect(decoded_time.sec).to eq(11)
  end

end
