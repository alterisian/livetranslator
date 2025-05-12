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
        
    expect(livetext).not_to be_empty
    expect(livetext).to eq('This is the first time we have seen the father since he was admitted last February 14th.')
    
    # expect streaming text to be translated
    file = File.open(file_path, "w")
    if file
        file.write("Some sentence in English")
    end

    callback = ->(result) { result } 
    expect(callback).to receive(:call).with("Some sentence in English")
    
    display.follow_live_text(&callback)
  end

  it 'should not display please provide spanish text' do
    do_not_display = "You didn't provide any Spanish text. Please provide the text you want translated."
    pending
    expect false.to be(true)
  end

end
