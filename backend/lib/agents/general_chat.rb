require 'json'

require_relative '../gemini/gemini'

module Agent
  class GeneralChat
    def initialize(options)
      api_key = File.read(File.join(Dir.home, '.secret', 'gemini.txt')).strip

      system_instruction = options[:system_instruction] || "あなたはコンピュータサイエンスの女子大生です。かわいいです。"
      @history = options[:history]
      @tools = options[:tools]
      @client = Gemini::Gemini.new(
        credentials: {
          service: 'generative-language-api',
          api_key: api_key
        },
        options: { model: 'gemini-2.0-flash-exp', server_sent_events: true, system_instruction: system_instruction }
      )
    end

    def is_agent?(result)
      result[:response]["function_call_result"] && 
        result[:response]["function_call_result"].is_a?(Hash) &&
        result[:response]["function_call_result"].key?(:agent_name)
    end

    def invoke(input)
      text = input[:interactions][:user_interaction]
      # puts "text: #{text}"
      # puts "chat history: #{history.get.inspect}"
  
      contents = @history.get
      contents += [{ role: 'user', parts: [{ text: text }] }]
      result = @client.generate_content({ contents: contents }, @tools)
  
      output = if is_agent?(result)
                 agent_info = result[:response]["function_call_result"]
                 p result[:response]["function_call_result"][:agent_name]
                 {
                   control: {
                     agent: "ROUTER",
                     status: "READY"
                   },
                   interactions: {
                     agent_name: agent_info[:agent_name],
                     user_interaction: agent_info[:user_interaction]
                   }
                 }
               else
                 if result[:response]["function_call_result"]
                   result = @client.handle_function_call_result(result, text, 
                                                                @history)
                 end
                 @history.add(result)
                 {
                   control: {
                     agent: self.class.name.downcase,
                     status: "RUNNING"
                   },
                   interactions: {
                     message: result[:response]["content"]["parts"][0]["text"]
                   }
                 }
               end
      output
    end
        
  end
end