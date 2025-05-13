require 'logger'
require 'listen'

# Displays translation files from the file system
class DisplayTranslation
  def initialize
    @logger = Logger.new($stdout)
    @logger.level = Logger::DEBUG
    @live_text_dir = 'live_text'
  end

  def display_live_text
    @logger.info("Scanning #{@live_text_dir} for text files...")
    last_text_file = Dir.glob(File.join(@live_text_dir, '*_EN.txt')).last
    return unless last_text_file

    file_text = File.read(last_text_file)
    @logger.info("last file: #{file_text}")
    file_text
  end

  def follow_live_text(&callback)
    Listen.logger = @logger
    listener = Listen.to(@live_text_dir) do |_modified, added, _removed|
      added.each do |file|
        # Process only files ending with _EN.txt
        next unless File.basename(file) =~ /_EN\.txt$/

        @logger.info("New file detected: #{file}")
        callback.call(File.read(file))
      end
    end
    listener.start
    @logger.info("Watching directory #{@live_text_dir}")
  end
end

if __FILE__ == $PROGRAM_NAME
  display = DisplayTranslation.new
  display.display_live_text
end
