require 'logger'
require 'listen'
require 'securerandom'
require 'fileutils'

class DisplayTranslation
    def initialize
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG
        @live_text_dir = 'live_text'
    end

    def generate_event_id(length=6)
        SecureRandom.hex(length / 2)
    end

    def create_event_directory
      event_id = generate_event_id
      events_base_dir = "events"
      Dir.mkdir(File.join(events_base_dir, event_id)) unless Dir.exist?(File.join(events_base_dir, event_id))

      event_id
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
    
end

if __FILE__ == $PROGRAM_NAME
    # Display Translation
    display = DisplayTranslation.new
    display.display_live_text
  end