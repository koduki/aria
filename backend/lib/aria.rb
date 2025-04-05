require_relative './gemini/gemini'
require_relative './tools'
require_relative './agents/general_chat'
require_relative './agents/windows_operator'

class Aria
  def initialize
    @agent = Agent::GeneralChat.new({history:Gemini::History.new, tools:Tools})
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
    p @agent.class.name.downcase
    agent_name = @agent.class.name.downcase
    interactions = @agents_meta[agent_name][:interactions].call(text)
    output = @agent.invoke({interactions: interactions})

    chat_response = if output[:control][:agent] == "ROUTER"
                      if output[:interactions][:agent_name] == "agent::windowsoperator"
                        @agent = Agent::WindowsOperator.new
                        chat(output[:interactions][:user_interaction])
                      end
                    elsif output[:control][:agent] == "agent::windowsoperator"
                      agent_name = output[:control][:agent]
                      @agents_meta[agent_name][:state][:task] = output[:interactions][:task]
                      output
                    else
                      output
                    end

    puts chat_response[:control][:status]
    if chat_response[:control][:status] == "FINISH"
      puts "finish agent::windowsoperator"
      change_agent(Agent::GeneralChat.new({history:Gemini::History.new, tools:Tools}))
    end
    chat_response
  end

  def change_agent(new_client)
    @agent = new_client
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
