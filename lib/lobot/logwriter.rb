class Lobot::Logwriter
  def initialize(file_name, options = {})
    @file_name = file_name
    @file = File.open(@file_name, 'w')
    @verbose = options.fetch(:verbose, false)
  end

  def <<(output)
    @file << output
    @file.flush
    STDOUT << output if @verbose
  end

  def close
    @file.close
  end

  def delete
    File.delete(@file_name)
  end
end