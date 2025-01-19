require 'net/http'
require 'uri'
require 'json'

# Geminiクラスを定義
class Gemini
  def initialize(credentials:, options:)
    @api_key = credentials[:api_key]
    @service = credentials[:service]
    @model = options[:model] || "gemini-1.5-flash"
    @server_sent_events = options[:server_sent_events] || false
  end

  def generate_content(payload)
    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{@model}:generateContent?key=#{@api_key}")
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = payload.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    response_body = JSON.parse(response.body)
    if response_body['candidates'] && !response_body['candidates'].empty?
          {
            request:payload,
            response:response_body['candidates'][0]
          }
    else
      nil
    end
  end

  def chat(text, history)
    puts "XXXXXXXXXXXXXX"

    p text
    p history
    puts "XXXXXXXXXXXXXX"
    generate_content({
      contents: history  + [{ role: 'user', parts: [{ text: text }] }]
    })
  end
end
