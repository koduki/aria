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
      @server_sent_events = options[:server_sent_events] || false
    end

    def generate_content(payload)
      system_instruction = {
        'system_instruction': {
          'parts': {
            'text': @system_instruction
          }
        }
      }
      generation_config = {
        'generationConfig': { 'response_mime_type': 'application/json' }
      }

      payload = system_instruction.merge(generation_config).merge(payload)

      # puts payload
      uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{@model}:generateContent?key=#{@api_key}")
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = payload.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      p response
      response_body = JSON.parse(response.body)
      if response_body['candidates'] && !response_body['candidates'].empty?
        {
          request: payload,
          response: response_body['candidates'][0]
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
