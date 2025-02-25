require_relative './gemini/gemini'
require_relative './tools'
require_relative './agents/general_chat'
require_relative './agents/windows_operator'

class Aria
  def initialize
    @task = nil
    @client = Agent::GeneralChat.new({history:Gemini::History.new, tools:Tools})
  end

  def chat text
    p @client.class.name.downcase
    output = if @client.class.name.downcase == "agent::generalchat"
               @client.invoke({
                                control: { agent: @client.class.name.downcase },
                                interactions: {
                                  user_interaction: text
                                }
                              })
             elsif @client.class.name.downcase == "agent::windowsoperator"
               @client.invoke({
                                control: { agent: @client.class.name.downcase },
                                interactions: {
                                  user_interaction: text,
                                  task: @task
                                }
                              })
             end

    chat_response = if output[:control][:agent] == "ROUTER"
                      if output[:interactions][:agent_name] == "agent::windowsoperator"
                        @client = Agent::WindowsOperator.new
                        chat(output[:interactions][:user_interaction])
                      end
                    elsif output[:control][:agent] == "agent::windowsoperator"
                      @task = output[:interactions][:task]
                      output_text = <<~EOS
      #{output[:interactions][:exec_result]}
      -------------
      thinking: #{output[:interactions][:thinking]}
      以下のコマンドを実行します。
      ```
      #{@task}
      ```

      ユーザへのリクエスト: #{output[:interactions][:request]}
                      EOS
                      {
                        control: {
                          agent: "agent::windowsoperator",
                          status: "RUNNING"
                        },
                        interactions: {
                          message: output_text
                        }
                      }
                    else
                      output
                    end
    chat_response
  end
end

if __FILE__ == $0
  aria = Aria.new
  while true
    print "> "
    user_input = gets.chomp
    reply = aria.chat(user_input)
    puts "begin"
    puts reply[:interactions][:message]
    puts "#end"
  end
end
