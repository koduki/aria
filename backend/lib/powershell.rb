require 'open3'

class PowerShell
  def initialize
    @powershell = IO.popen('powershell', 'r+')
  end

 def run(command)
    @powershell.puts(command)
    output = ''
    loop do
      ready = IO.select([@powershell], [], [], 0.1) # Timeout after 0.1 seconds
      break unless ready

      begin
        output += @powershell.read_nonblock(256)
      rescue EOFError
        break
      end
    end
    { stdout: output, stderr: '', status: $? }
  end

  def close
    @powershell.close
  end
end

# Test code
ps = PowerShell.new
result = ps.run('$testVar = "Hello from PowerShell"')
puts "Result 1: #{result[:stdout]}"

result2 = ps.run('Write-Host $testVar')
puts "Result 2: #{result2[:stdout]}"

ps.close
