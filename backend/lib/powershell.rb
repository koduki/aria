require 'open3'
require 'nkf' # nkf を require に追加

class PowerShell
  def initialize
    command = String.new('powershell -NoLogo -NonInteractive -NoProfile -ExecutionPolicy Bypass')
    @stdin, @stdout, @stderr, @wait_thr = Open3.popen3(command)
  end

  def invoke(command)
    @stdin.puts(command)
    @stdin.flush
    sleep(0.1) # コマンド実行待ち（必要に応じて調整）
    out_buffer = ''
    err_buffer = ''

    loop do
      ready = IO.select([@stdout, @stderr], nil, nil, 0.1)
      break unless ready

      ready[0].each do |io|
        begin
          chunk = io.read_nonblock(256)
          # chunk = chunk.encode('UTF-8', invalid: :replace, undef: :replace) # 削除
          chunk = NKF.nkf('-w', chunk.force_encoding('Shift_JIS')) # 修正

          if io == @stdout
            out_buffer += chunk
          else
            err_buffer += chunk
          end
        rescue EOFError, IO::WaitReadable
          next
        end
      end
    end

    # 不要な行を除去
    out_lines = out_buffer.split("\n")
    out_actual = out_lines.reject { |line| line.strip.start_with?('PS ') || line.include?('PSReadline') }

    err_lines = err_buffer.split("\n")
    err_actual = err_lines.reject { |line| line.strip.start_with?('PS ') || line.include?('PSReadline') }
    
    {
      stdout: out_actual.join("\n"),
      stderr: err_actual.join("\n"),
      status: (err_actual.empty? ? 0 : 1)
    }
  end

  def close
    @stdin.puts("exit")
    @stdin.flush
    @stdin.close unless @stdin.closed?
    @stdout.close unless @stdout.closed?
    @stderr.close unless @stderr.closed?
    @wait_thr.join if @wait_thr
  end
end
