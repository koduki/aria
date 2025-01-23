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

class History
  def initialize()
    @history = []
  end
  def add_message(message)
    @history.push(message)
  end
  def get_messages()
    @history
  end
  def store(result)
    if result
      # ユーザーの入力を保存
      user_message = { role: 'user', parts: [{ text: result[:request][:contents][-1][:parts][0][:text] }] }
      add_message(user_message)

      # モデルの応答を保存
      model_message = { role: 'model', parts: [{ text: result[:response]["content"]["parts"][0]["text"] }] }
      add_message(model_message)

      puts "Session history updated: #{get_messages.inspect}"
    end
  end
end

# グローバル変数として History クラスのインスタンスを保持
$history = History.new

post '/api/chat' do
  content_type :json
  request_body = JSON.parse(request.body.read)
  text = request_body['text']

  result = client.chat(text, $history)

  result.to_json
end
