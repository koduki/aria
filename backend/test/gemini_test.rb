require 'minitest/autorun'
require_relative '../lib/gemini'

class GeminiTest < Minitest::Test
  #
  # LLMのテストなので実行結果のAssertは意図的にせずに出力をチェックのみ
  #
  def test_chat
    api_key = File.read(File.join(Dir.home, '.secret', 'gemini.txt')).strip
    gemini = Gemini::Gemini.new(
      credentials: {
        service: 'generative-language-api',
        api_key: api_key
      },
      options: { model: 'gemini-2.0-flash-exp', system_instruction:"これは対話アプリなので回答は短くしてください。" }
    )

    history = Gemini::History.new
    r = gemini.chat("今日の映画は？", history)
    puts "request"
    p r[:request]
    puts "response"
    p r[:response]
  end
end

