# Module for Audio file operations
module AudioFile
  # Audio file struct class
  class File
    attr_reader :path, :ext, :base_name

    def initialize(path)
      @path = path
      @ext = ::File.extname(path)
      @base_name = ::File.basename(path, @ext)
    end

    def properties
      {
        size_bytes: ::File.size(@path),
        created_at: ::File.ctime(@path),
        path: @path,
        filename: ::File.basename(@path)
      }
    end

    def format
      @ext.downcase.delete_prefix('.')
    end
  end
end
