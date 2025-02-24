require 'json'

require_relative '../gemini/gemini'

module Agent
    class GeneralChat
        def initialize(options)
            api_key = File.read(File.join(Dir.home, '.secret', 'gemini.txt')).strip
            sysprompt = open(File.join(__dir__, "./prompts/powershell.txt")).read

            @history = options[:history]
            @tools = options[:tools]
            @client = Gemini::Gemini.new(
                credentials: {
                    service: 'generative-language-api',
                    api_key: api_key
                },
                options: { model: 'gemini-2.0-flash-exp', server_sent_events: true, system_instruction:"あなたはコンピュータサイエンスの女子大生です。かわいいです。" }
            )
        end

        def is_agent?(func_result)
            func_result.is_a?(Hash) && func_result.key?(:agent_name)
        end

        def invoke(input)
            # puts "text: #{text}"
            # puts "chat history: #{history.get.inspect}"
      
            # contentsを初期化 (history を考慮)
            contents = @history.get
            contents += [{ role: 'user', parts: [{ text: input[:interactions][:user_interaction] }] }]
            result = @client.generate_content({ contents: contents }, @tools)
      p result[:request]
      
            if result[:response]["function_call_result"] && !is_agent?(result[:response]["function_call_result"])
              result = @client.handle_function_call_result(result, text, @history)
            end
      
            @history.add(result) unless is_agent?(result[:response]["function_call_result"])
           
            return {
                control: {
                  agent: self.class.name.downcase,
                  finish: true
                },
                interactions: {
                  message: result[:response]["content"]["parts"][0]["text"]
                }
            }
        end
          
    end
end