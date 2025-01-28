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
      user_message = { role: 'user', parts: [{ text: result[:request][:contents][-1][:parts][0][:text] }] }
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

    def generate_content(payload)
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

      tools = {}

      def find_movies(location, description)
        puts "find_movies called with location: #{location}, description: #{description}"
        return "Hello"
      end

      tools["find_movies"] = method(:find_movies)

      tools_def = {
        "tools": [
          {
            "function_declarations": [
              {
                "name": "find_movies",
                "description": "find movie titles currently playing in theaters based on any description, genre, title words, etc.",
                "parameters": {
                  "type": "object",
                  "properties": {
                    "location": {
                      "type": "string",
                      "description": "The city and state, e.g. San Francisco, CA or a zip code e.g. 95616"
                    },
                    "description": {
                      "type": "string",
                      "description": "Any kind of description including category or genre, title words, attributes, etc."
                    }
                  },
                  "required": [
                    "description"
                  ]
                }
              }
            ]
          }
        ]
      }
      tool_config = {
        "tool_config": {
          "function_calling_config": {
            "mode": "ANY"
          },
        }
      }
      payload = system_instruction.merge(generation_config).merge(tools_def).merge(tool_config).merge(payload)

      # puts payload
      uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{@model}:generateContent?key=#{@api_key}")
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = payload.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      response_body = JSON.parse(response.body)
      if response_body['candidates'] && !response_body['candidates'].empty?
        candidate = response_body['candidates'][0]
        if candidate && candidate['content'] && candidate['content']['parts'] && candidate['content']['parts'][0]
          part = candidate['content']['parts'][0]
          if part['functionCall']
            function_name = part['functionCall']['name']
            function_args = part['functionCall']['args']
            if tools && tools[function_name]
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

    def chat(text, history)
      puts "text: #{text}"
      puts "chat history: #{history.get.inspect}"

      # contentsを初期化 (history を考慮)
      contents = history.get

      # 新しいユーザーメッセージを追加
      contents += [{ role: 'user', parts: [{ text: text }] }]
      result = generate_content({ contents: contents})
      history.add(result)
      result
    end
  end
end
