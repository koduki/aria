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
    result = @ps.run('Write-Host "Hello, World!"')
    assert_includes result[:stdout], "Hello, World!"
  end

  def test_variable_persistence
    @ps.run('$testVar = "Test Value"')
    result = @ps.run('Write-Host $testVar')
    assert_includes result[:stdout], "Test Value"
  end

  def test_multiple_commands
    result1 = @ps.run('$x = 5')
    result2 = @ps.run('$y = 3')
    result3 = @ps.run('Write-Host ($x + $y)')
    assert_includes result3[:stdout], "8"
  end

  def test_command_output_structure
    result = @ps.run('Write-Host "Test"')
    assert_kind_of Hash, result
    assert_includes result.keys, :stdout
    assert_includes result.keys, :stderr
    assert_includes result.keys, :status
  end
end
