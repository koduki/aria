require 'minitest/autorun'
require_relative '../lib/gemini/gemini'
require_relative '../lib/tools'

class GeminiTest < Minitest::Test
  def _init_gemini
    api_key = File.read(File.join(Dir.home, '.secret', 'gemini.txt')).strip
    gemini = Gemini::Gemini.new(
      credentials: {
        service: 'generative-language-api',
        api_key: api_key
      },
      options: { model: 'gemini-2.0-flash-exp', system_instruction:"これは対話アプリなので回答は短くしてください。" }
    )
  end

  #
  # LLMのテストなので実行結果のAssertは意図的にせずに出力をチェックのみ
  #
  def test_chat
    gemini = _init_gemini()

    history = Gemini::History.new
    r = gemini.chat("今日の映画は？　ジャンルはアニメでロスに住んでます", {history:history, tools:Tools})
    # puts "request"
    # p r[:request]
    # puts "response"
    # p r[:response]
  end

  def test_generate_content
    gemini = _init_gemini()

    payload = {
      "contents": [{
        "parts":[
          {"text": "List 5 popular cookie recipes"}
          ]
      }]
    }

    r = gemini.generate_content(payload)
    # puts "request"
    # p r[:request]
    # puts "response"
    # p r[:response]

    assert_equal payload[:contents], r[:request][:contents]
    assert_equal({:parts => {:text => "これは対話アプリなので回答は短くしてください。"}}, r[:request][:system_instruction])

    assert r[:response]["content"]["parts"][0]["text"] != nil
    assert_equal "model", r[:response]["content"]["role"]
  end

  def test_generate_content_with_function_calling
    gemini = _init_gemini()

    payload = {
      "contents": [{
        "parts":[
          {"text": "List 5 popular cookie recipes"}
          ]
      }]
    }

    r = gemini.generate_content(payload, Tools, "function_calling_config": {"mode": "ANY"})
    # puts "request"
    # p r[:request]
    # puts "response"
    # p r[:response]

    assert_equal payload[:contents], r[:request][:contents]
    assert_equal({:parts => {:text => "これは対話アプリなので回答は短くしてください。"}}, r[:request][:system_instruction])
    assert r[:request][:tools] != nil
    
    assert r[:response]["content"]["parts"][0]["functionCall"] != nil
    assert r[:response]["function_call_result"] != nil
  end
end
