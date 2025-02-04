require 'sinatra'
require 'json'
require_relative './lib/gemini/gemini'
require_relative './lib/tools'

# API keyの読み込み
api_key = File.read(File.join(Dir.home, '.secret', 'gemini.txt')).strip

# クライアントオブジェクトを作成
client = Gemini::Gemini.new(
  credentials: {
    service: 'generative-language-api',
    api_key: api_key
  },
  options: { model: 'gemini-2.0-flash-exp', server_sent_events: true, system_instruction:"あなたはコンピュータサイエンスの女子大生です。かわいいです。" }
)

# グローバル変数として History クラスのインスタンスを保持
$history = Gemini::History.new

post '/api/chat' do
  content_type :json
  request_body = JSON.parse(request.body.read)
  text = request_body['text']

  result = client.chat(text, {history:$history, tools:Tools})

  result.to_json
end
