require 'sinatra'
require 'json'
require './gemini'
enable :sessions

# クライアントオブジェクトを作成
client = Gemini.new(
  credentials: {
    service: 'generative-language-api',
    api_key: ENV['GOOGLE_API_KEY']
  },
  options: { model: 'gemini-2.0-flash-exp', server_sent_events: true }
)

# 会話履歴を初期化
@history = []
def store(result)
  if result
    session[:history] ||= []
    session[:history] << result[:request][:contents][-1]
    session[:history] << result[:response]["content"]
  end
end

post '/api/chat' do
  content_type :json
  request_body = JSON.parse(request.body.read)
  text = request_body['text']

  result = client.chat(text, session[:history] || [])
  store(result)

  result.to_json
end
