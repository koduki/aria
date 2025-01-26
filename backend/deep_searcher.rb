require 'json'
require 'erb'

require './gemini'
require './web_search'
require './web_client'

module Agent
  class DeepSearcher
    def initialize
      @api_key = File.read(File.join(Dir.home, '.secret', 'gemini.txt')).strip
    end

    def invoke(user_request)
      puts "==== Creating strategy"
      strategy = make_strategy(user_request)
      puts "==== Seaching contents"
      contents = search(strategy["search-themes"])
      puts "==== Generate report"
      report = generate_report(contents, strategy["report-creation-prompt"])
      report
    end

    def make_strategy(user_request)
      prompt_path = "prompts/deep_research_strategy.json.erb"
      prompt = ERB.new(File.read(prompt_path)).result_with_hash({ user_request: user_request })
      
      client = Gemini::Gemini.new(
        credentials: {
          service: 'generative-language-api',
          api_key: @api_key
        },
        options: { model: 'gemini-2.0-flash-thinking-exp'}
      )
      r = client.generate_content({
          contents: [{ role: 'user', parts: [{ text: prompt }] }]
      })

      puts r[:response]["content"]["parts"][0]["text"]
      JSON.parse(r[:response]["content"]["parts"][0]["text"])
    end

    def _extract_content(url)
      begin
        content_data = WebClient.new.open(url, headless: true) do |driver|
          title = driver.title
          body = driver.find_element(tag_name: 'body').text.gsub(/\s+/, ' ').strip
          { title: title, body: body }
        end
        return content_data
      rescue => e
        puts "An unexpected error occurred while fetching #{url}: #{e.message}"
        return { title: nil, body: nil }
      end
    end

    def search(search_themes)
      results = []
      search_themes.each do |theme_data|
        theme_name = theme_data["theme"]
        puts "テーマ名:#{theme_name}, #{(results.size + 1)}/#{search_themes.size}"

        item_words = []
        theme_data["search-words"].each do |search_word|
          puts "Search Words: #{ (item_words.size + 1)}/#{theme_data["search-words"].size}"
          search_results = WebSearch.new.search(search_word)

          item_contents = []
          search_results.take(3).each do |result|
            puts "Extract Contents START: #{ (item_contents.size + 1)}/3}"
            if result[:url]
              start_time = Time.now
              content = _extract_content(result[:url])
              end_time = Time.now

              item_contents << {
                url: result[:url],
                title: content[:title],
                body: content[:body]
              }
            end
            puts "Extract Contents END: #{end_time - start_time}秒"
          end
          item_words << {
            words: search_word,
            contents: item_contents
          }
        end
        results << {
            theme: theme_name,
            contents: item_words
        }
      end

      JSON.pretty_generate(results)
    end
  end
end

def generate_report(contents, prompt)
  client = Gemini::Gemini.new(
    credentials: {
      service: 'generative-language-api',
      api_key: @api_key
    },
    options: { model: 'gemini-2.0-flash-exp', system_instruction:prompt}
  )
  r = client.generate_content({
      contents: [{ role: 'user', parts: [{ text: contents }] }]
  })
  puts "============= Report"
  puts r[:response]["content"]["parts"][0]["text"]
end

Agent::DeepSearcher.new.invoke "Amazon DSQL、Google Cloud Spanner、TiDBを比較して。比較表も欲しい。"
