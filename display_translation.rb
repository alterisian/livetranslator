require 'logger'
require 'listen'
require 'time'

class DisplayTranslation
    def initialize
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG
        @live_text_dir = 'live_text'
    end

    def display_live_text
        @logger.info("Scanning #{@live_text_dir} for text files...")
        last_text_file = Dir.glob(File.join(@live_text_dir, '*_EN.txt')).last
        if last_text_file
          file_text = File.open(last_text_file).read
          @logger.info("last file: #{file_text}")
          file_text
        end
    end

    def follow_live_text(&callback)
        listener = Listen.to(@live_text_dir) do |modified, added, _removed|
            added.each do |file|
              # Process only files ending with _EN.txt
              if File.basename(file) =~ /_EN\.txt\z/
                @logger.info("New file detected: #{file}")
                file_text = File.read(file)
                callback.call(file_text)
                stop_watching = true
                listener.stop
              end
            end
          end
        listener.start
        # watch live text for new files to appear
        # we could poll the dir
        # we could use a file watcher
        # callback.call("something")
    end

    def decode_time_from_filename(filename)      
      timestamp_str = filename.split('_')[2]      
      Time.at(timestamp_str.to_i)
    end
  
end

if __FILE__ == $PROGRAM_NAME
  display = DisplayTranslation.new
  display.display_live_text
end