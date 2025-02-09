require 'open3'

class PowerShell
  def initialize
    @powershell = IO.popen('powershell', 'r+')
  end

 def run(command)
    @powershell.puts(command)
    sleep(0.1) # Wait for command to execute
    output = ''
    loop do
      ready = IO.select([@powershell], [], [], 0.1) # Timeout after 0.1 seconds
      break unless ready

      begin
        chunk = @powershell.read_nonblock(256)
        # Only include lines that start with the command output
        output += chunk.encode('UTF-8', invalid: :replace, undef: :replace)
      rescue EOFError
        break
      end
    end
    
    # Extract actual command output (after the prompt)
    lines = output.split("\n")
    actual_output = lines.select { |line| !line.strip.start_with?('PS ') && !line.include?('PSReadline') }
    { stdout: actual_output.join("\n"), stderr: '', status: $? }
  end

  def close
    @powershell.close
  end
end
