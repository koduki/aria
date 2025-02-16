load 'lib/powershell.rb'
@ps = PowerShell.new

require 'json'

require_relative './gemini/gemini'

history = Gemini::History.new
@api_key = File.read(File.join(Dir.home, '.secret', 'gemini.txt')).strip
sysprompt = open('prompts/powershell.txt').read
client = Gemini::Gemini.new(
credentials: {
    service: 'generative-language-api',
    api_key: @api_key
},
options: { model: 'gemini-2.0-flash-exp', system_instruction:sysprompt, json_mode:true}
)


def parse(text)
    trimed_data = text.sub(/\A```json\s*/, '').sub(/\s*```\z/, '')
    JSON.parse(trimed_data)
end

def exec command
    command_cp932 = command.encode("CP932", invalid: :replace, undef: :replace)
    @ps.invoke(command_cp932)
end

def generate_content exec_r
    contents = if exec_r[:status] == 0
        exec_r[:stdout]
        contents="以下の実行結果になりました。ユーザリクエストを満たす次のコマンドを生成してください.\n#{exec_r[:stderr]}"
    else
        contents="以下のエラーが発生しました。問題解決のためにコマンドを修正してください.\n#{exec_r[:stderr]}"
    end
    contents
end

content = "Videoディレクトリの8月の動画をフォルダにまとめて"
while(true) do
    llm_res = client.chat(content, {history:history})
    response = parse(llm_res[:response]["content"]["parts"][0]["text"])
    p response["finish"]
    break if response["finish"]
    puts "thinking: #{response["thinking"]}"

    command = response["task"]
    puts "cmd: #{command}"
    exec_r = exec command
    content = generate_content(exec_r)
end

puts "DONE"
