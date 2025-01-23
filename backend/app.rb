require 'sinatra'
require 'json'
require './gemini'

# API keyの読み込み
api_key = File.read(File.join(Dir.home, '.secret', 'gemini.txt')).strip

# クライアントオブジェクトを作成
client = Gemini.new(
  credentials: {
    service: 'generative-language-api',
    api_key: api_key
  },
  options: { model: 'gemini-2.0-flash-exp', server_sent_events: true }
)

# インメモリで履歴を管理
$history = []

def store(result)
  if result
    # ユーザーの入力を保存
    user_message = { role: 'user', parts: [{ text: result[:request][:contents][-1][:parts][0][:text] }] }
    $history << user_message

    # モデルの応答を保存
    model_message = { role: 'model', parts: [{ text: result[:response]["content"]["parts"][0]["text"] }] }
    $history << model_message

    puts "Session history updated: #{$history.inspect}"
  end
end

post '/api/chat' do
  content_type :json
  request_body = JSON.parse(request.body.read)
  text = request_body['text']

  puts "Current session history: #{$history.inspect}"
  result = client.chat(text, $history)
  store(result)

  result.to_json
end
