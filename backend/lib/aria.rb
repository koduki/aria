require_relative './gemini/gemini'
require_relative './tools'
require_relative './agents/general_chat'

class Aria
  def initialize
    @client = Agent::GeneralChat.new({history:Gemini::History.new, tools:Tools})
  end

  def chat text
    output = @client.invoke({
      control: { agent: @client.class.name.downcase },
      interactions: {
        user_interaction: text
      }
    })

    if output[:control][:agent] == "windows_operator"

      res = output[:response]["function_call_result"]
      puts "============"
      puts res[:agent_name]
      puts res[:user_request]
      puts "============"
      @client = Agent::WindowsOperator.new

    else
      output
    end
  end
end

if __FILE__ == $0
    aria = Aria.new
    while true
        print "> "
        user_input = gets.chomp
        reply = aria.chat(user_input)
        p reply
        puts "#begin"
        puts reply[:interactions][:message]
        puts "#end"
    end
end
