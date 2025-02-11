require 'minitest/autorun'
require_relative '../lib/powershell'

class PowerShellTest < Minitest::Test
  def setup
    @ps = PowerShell.new
  end

  def teardown
    @ps.close
  end

  def test_simple_command
    result = @ps.invoke('Write-Host "Hello, World!"')
    assert_includes result[:stdout], "Hello, World!"
  end

  def test_variable_persistence
    @ps.invoke('$testVar = "Test Value"')
    result = @ps.invoke('Write-Host $testVar')
    assert_includes result[:stdout], "Test Value"
  end

  def test_multiple_commands
    result1 = @ps.invoke('$x = 5')
    result2 = @ps.invoke('$y = 3')
    result3 = @ps.invoke('Write-Host ($x + $y)')
    assert_includes result3[:stdout], "8"
  end

  def test_command_output_structure
    result = @ps.invoke('Write-Host "Test"')
    assert_kind_of Hash, result
    assert_includes result.keys, :stdout
    assert_includes result.keys, :stderr
    assert_includes result.keys, :status
  end

  def test_stderr_generation
    result = @ps.invoke('Write-Error "意図的なエラーです"')
    p result
    assert_includes result[:stderr], "意図的なエラーです"
    assert_operator result[:status], :>, 0
  end

  def test_multiline_command
    multiline_command = <<~POWERSHELL
      $x = 10
      $y = 20
      Write-Host ($x + $y)
    POWERSHELL
    result = @ps.invoke(multiline_command)
    assert_includes result[:stdout], "30"
  end
end
