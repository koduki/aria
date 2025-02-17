require 'json'

require_relative '../gemini/gemini'
require_relative '../powershell.rb'

module Agent
    class WindowsOperator
        def initialize()
            @ps = PowerShell.new
            @history = Gemini::History.new
            @api_key = File.read(File.join(Dir.home, '.secret', 'gemini.txt')).strip
            sysprompt = open('prompts/powershell.txt').read

            @client = Gemini::Gemini.new(
            credentials: {
                service: 'generative-language-api',
                api_key: @api_key
            },
            options: { model: 'gemini-2.0-flash-exp', system_instruction:sysprompt, json_mode:true}
            )
        end

        def invoke(agent_response, user_response)
            exec_result = ""
            if user_response == "y"
                command = agent_response["task"]
                r = generate_prompt(ps_exec(command))
                content = r[:prompt]
                exec_result = r[:result]
            else
                content = user_response
            end

            llm_response = @client.chat(content, {history:@history})
            response = parse(llm_response[:response]["content"]["parts"][0]["text"])
            response["exec_result"] = exec_result
            response
        end

        private

        def parse(text)
            trimed_data = text.sub(/\A```json\s*/, '').sub(/\s*```\z/, '')
            JSON.parse(trimed_data)
        end

        def ps_exec(command)
            command_cp932 = command.encode("CP932", invalid: :replace, undef: :replace)
            @ps.invoke(command_cp932)
        end

        def generate_prompt(exec_result)
            if exec_result[:status] == 0
                {
                    result: exec_result[:stdout],
                    prompt:"以下の実行結果になりました。ユーザリクエストを満たす次のコマンドを生成してください.\n#{exec_result[:stdout]}"
                }
            else
                {
                    result: exec_result[:stderr],
                    prompt:"以下のエラーが発生しました。問題解決のためにコマンドを修正してください.\n#{exec_result[:stderr]}"
                }
            end
        end
    end
end

if __FILE__ == $0
    # content = "Videoディレクトリの9月の動画をフォルダにまとめて"
    agent = Agent::WindowsOperator.new
    agent_response = nil
    while true
        print "> "
        user_response = gets.chomp
        agent_response = agent.invoke(agent_response, user_response)

        puts "output: #{agent_response["exec_result"]}" unless agent_response["exec_result"].empty? 

        output = <<~EOS
        thinking: #{agent_response["thinking"]}
        以下のコマンドを実行します。
        ```
        #{agent_response["task"]}
        ```

        ユーザへのリクエスト: #{agent_response["request"]}
        ==============
        EOS
        puts "#{output}"
        
        break if agent_response["finish"]
    end
    puts "終了"
end
