require 'json'

require_relative '../gemini/gemini'
require_relative '../powershell.rb'

module Agent
  class WindowsOperator
    def initialize()
      sysprompt = open(File.join(__dir__, "./prompts/powershell.txt")).read
      @ps = PowerShell.new
      @client = Agent::GeneralChat.new({history:Gemini::History.new, system_instruction:sysprompt})
    end

    def invoke(input)
      exec_result = ""
      if "y" == input[:interactions][:user_interaction]
        p input
        command = input[:interactions][:task]
        r = generate_prompt(ps_exec(command))
        content = r[:prompt]
        exec_result = r[:result]
      else
        content = input[:interactions][:user_interaction]
      end

      llm_response = @client.invoke({
                                      control: { agent: "agent::generalchat"},
                                      interactions: {
                                        user_interaction: content
                                      }
                                    })

      response = parse(llm_response[:interactions][:message])
      p response
      {
        control: {
          agent: self.class.name.downcase,
          status: response["status"] 
        },
        interactions: {
          exec_result: exec_result,
          thinking: response["thinking"],
          task: response["task"],
          request: response["request"]
        }
      }
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
          prompt: "以下の実行結果になりました。ユーザリクエストを満たす次のコマンドを生成してください.\n#{exec_result[:stdout]}"
        }
      else
        {
          result: exec_result[:stderr],
          prompt: "以下のエラーが発生しました。問題解決のためにコマンドを修正してください.\n#{exec_result[:stderr]}"
        }
      end
    end
  end
end
