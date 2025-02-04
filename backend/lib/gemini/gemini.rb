require 'net/http'
require 'uri'
require 'json'

module Gemini
  class History
    def initialize
      @history = []
    end

    def get
      @history
    end

    def add(result)
      return unless result

      # ユーザーの入力を保存
      user_message = if result[:request][:contents][1] and result[:request][:contents][1][:parts][0][:functionCall]
        { role: 'user', parts: [{ text:result[:request][:contents][0][:parts][0][:text] }] }
      else
        { role: 'user', parts: [{ text: result[:request][:contents][-1][:parts][0][:text] }] }
      end
      @history.push(user_message)

      # モデルの応答を保存
      model_message = { role: 'model', parts: [{ text: result[:response]['content']['parts'][0]['text'] }] }
      @history.push(model_message)      

      puts "history updated: #{@history.inspect}"
    end
  end

  class Gemini
    def initialize(credentials:, options:)
      @api_key = credentials[:api_key]
      @service = credentials[:service]
      @model = options[:model] || 'gemini-1.5-flash'
      @system_instruction = options[:system_instruction] || ''
      @json_mode = options[:json_mode] || false
    end

    def generate_content(payload, tool_methods = nil, tool_config=nil)
      system_instruction = {
        'system_instruction': {
          'parts': {
            'text': @system_instruction
          }
        }
      }
      generation_config = if @json_mode
                            {
                              'generationConfig': { 'response_mime_type': 'application/json' }
                            }
                          else
                            {}
                          end
      tools_payload = {}
      if tool_methods
        tools = tool_methods.methods(false).each_with_object({}) do |method_name, hash|
          hash[method_name] = tool_methods.method(method_name)
        end

        tools_def = {
          "tools": [
            {
              "function_declarations": tools.keys.map { |tool_name| FunctionDecorator.to_def(tool_name) }
            }
          ]
        }

        tool_options = if tool_config.nil?
          {
            "tool_config": {
              "function_calling_config": {
                "mode": "AUTO"
              },
            }
          }
        else
          { "tool_config": tool_config }
        end
        tools_payload = tools_def.merge(tool_options)
      end

      payload = system_instruction.merge(generation_config).merge(tools_payload).merge(payload)

      # puts payload
      uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{@model}:generateContent?key=#{@api_key}")
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = payload.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
      response_body = JSON.parse(response.body)
      # puts response_body
      if response_body['candidates'] && !response_body['candidates'].empty?
        candidate = response_body['candidates'][0]
        if candidate && candidate['content'] && candidate['content']['parts'] && candidate['content']['parts'][0]
          part = candidate['content']['parts'][0]
          if part['functionCall']
            function_name = part['functionCall']['name'].to_sym
            function_args = part['functionCall']['args']
            if tools[function_name]
              function_values = tools[function_name]
                .parameters
                .map { |_, name| function_args[name.to_s] }
              candidate['function_call_result'] = tools[function_name].call(*function_values)
            end
          end
        end

        {
          request: payload,
          response: candidate
        }
      else
        nil
      end
    end

    def handle_function_call_result(result, text, history)
      function_call = { role: 'model', parts: [{ functionCall: result[:response]['content']['parts'][0]['functionCall'] }] }
      func_name = function_call[:parts][0][:functionCall]["name"]

      function_result = { 
        role: 'user', 
        parts: [{
          "functionResponse": {
            "name": func_name,
            "response": {
              "name": func_name,
              "content": result[:response]["function_call_result"]
            }
          }
        }]
      }

      contents = history.get
      contents += [{ role: 'user', parts: [{ text: text }] }]
      contents += [function_call]
      contents += [function_result]

      generate_content({ contents: contents })
    end

    def chat(text, options)
      history = options[:history]
      tools = options[:tools]
      # puts "text: #{text}"
      puts "chat history: #{history.get.inspect}"

      # contentsを初期化 (history を考慮)
      contents = history.get

      # 新しいユーザーメッセージを追加
      contents += [{ role: 'user', parts: [{ text: text }] }]
      result = generate_content({ contents: contents }, tools)

      if result[:response]["function_call_result"]
        result = handle_function_call_result(result, text, history)
      end

      history.add(result)
      result
    end
  end
end
