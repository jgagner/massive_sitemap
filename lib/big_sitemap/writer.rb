require 'fileutils'
require 'zlib'
require 'stringio'

class BigSitemap

  # Write into String
  # Perfect for testing porpuses
  class StringWriter < StringIO
    def init! # do noting
    end

    def close! # do noting
    end
  end

  # Write into File
  # On rotation, close current file, and reopen a new one
  # with same file name but -<counter> appendend
  #
  # TODO what if file exists?, overwrite flag??
  class FileWriter

    def initialize(file_name_template)
      @stream_name_template = file_name_template
      @stream_names = []
    end

    # API
    def init!
      close! if @stream
      @stream = File.open(tmp_file_name, 'w+:ASCII-8BIT')
    end

    def close!
      @stream.close
      @stream = nil
      # Move from tmp_file into acutal file
      File.delete(file_name) if File.exists?(file_name)
      File.rename(tmp_file_name, file_name)
      @stream_names << file_name
    end

    def print(string)
      @stream.print(string)
    end

    private
    def file_name
      cnt = @stream_names.size == 0 ? "" : "-#{@stream_names.size}"
      ext = File.extname(@stream_name_template)
      @stream_name_template.gsub(ext, cnt + ext)
    end

    def tmp_file_name
      file_name + ".tmp"
    end
  end

  # Write into GZipped File
  class GzipFileWriter < FileWriter
    def initialize(file_name_template)
      super(file_name_template + ".gz")
    end

    def init!
      super
      @stream = ::Zlib::GzipWriter.new(@stream)
    end
  end

  class LockingFileWriter < FileWriter
    LOCK_FILE = 'generator.lock'

    def init!
      close! if @stream
      File.open(LOCK_FILE, 'w', File::EXCL) #lock!
      super
    rescue Errno::EACCES => e
      raise 'Lockfile exists'
    end

    def close!
      super
      FileUtils.rm LOCK_FILE #unlock!
    end
  end

end