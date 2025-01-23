require 'sinatra'
require 'json'
require './gemini'

# API keyの読み込み
api_key = File.read(File.join(Dir.home, '.secret', 'gemini.txt')).strip

# クライアントオブジェクトを作成
client = Gemini::Gemini.new(
  credentials: {
    service: 'generative-language-api',
    api_key: api_key
  },
  options: { model: 'gemini-2.0-flash-exp', server_sent_events: true }
)

# グローバル変数として History クラスのインスタンスを保持
$history = Gemini::History.new

post '/api/chat' do
  content_type :json
  request_body = JSON.parse(request.body.read)
  text = request_body['text']

  result = client.chat(text, $history)

  result.to_json
end
