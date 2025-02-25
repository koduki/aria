require_relative './gemini/gemini'
require_relative './tools'
require_relative './agents/general_chat'
require_relative './agents/windows_operator'

class Aria
  def initialize
    @client = Agent::GeneralChat.new({history:Gemini::History.new, tools:Tools})
    @agents_meta = {
      "agent::generalchat" => {
        interactions: lambda do |text|
          {
            user_interaction: text
          }
        end,
        state: {}
      },
      "agent::windowsoperator" => {
        interactions: lambda do |text|
          {
            user_interaction: text,
            task: @agents_meta["agent::windowsoperator"][:state][:task]
          }
        end,
        state: {}
      }
    }
  end

  def chat text
    p @client.class.name.downcase
    agent_name = @client.class.name.downcase
    interactions = @agents_meta[agent_name][:interactions].call(text)
    output = @client.invoke({interactions: interactions})

    chat_response = if output[:control][:agent] == "ROUTER"
                      if output[:interactions][:agent_name] == "agent::windowsoperator"
                        @client = Agent::WindowsOperator.new
                        chat(output[:interactions][:user_interaction])
                      end
                    elsif output[:control][:agent] == "agent::windowsoperator"
                      agent_name = output[:control][:agent]
                      @agents_meta[agent_name][:state][:task] = output[:interactions][:task]
                      output
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
    case reply[:control][:agent]
    when "agent::windowsoperator"
      puts <<~EOS
      #{reply[:interactions][:exec_result]}
      -------------
      thinking: #{reply[:interactions][:thinking]}
      以下のコマンドを実行します。
      ```
      #{reply[:interactions][:task]}
      ```

      ユーザへのリクエスト: #{reply[:interactions][:request]}
      EOS
    else
      puts reply[:interactions][:message]
    end
    puts "#end"
  end
end
