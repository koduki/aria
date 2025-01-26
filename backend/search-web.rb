require 'selenium-webdriver'
require 'json'
require 'cgi'

class WebClient
  def open(url, options = {})
    begin
      wait = Selenium::WebDriver::Wait.new(timeout: 10) # 最大10秒待機

      selenium_options = Selenium::WebDriver::Edge::Options.new
      selenium_options.add_argument('--log-level=3') # 0: INFO, 1: WARNING, 2: LOG_ERROR, 3: LOG_FATAL

      headless = options[:headless]
      if headless.nil? || headless == true
        selenium_options.add_argument('--headless')
      end
      driver = Selenium::WebDriver.for :edge, options: selenium_options
      driver.get(url)

      if options[:wait_element]
        begin
          wait.until { driver.find_element(css: options[:wait_element]) }
        rescue Selenium::WebDriver::Error::TimeoutError => e
          puts "タイムアウトエラー: '#{options[:wait_element]}'要素が見つかりませんでした"
          puts "エラー詳細: #{e.message}"
          return []
        end
      end

      # puts "open: #{url}"
      result = yield driver if block_given? # ブロックが与えられた場合のみ実行
      driver.quit

      result
    rescue Selenium::WebDriver::Error::WebDriverError => e
      puts "Selenium WebDriver エラー: #{e.message}"
      return [] # エラー発生時は空の配列を返す
    rescue => e
      puts "予期しないエラーが発生しました: #{e.message}"
      return [] # 予期しないエラー発生時も空の配列を返す
    end
  end
end

class SearchWeb
  def initialize()
    @input_file = "input.json"
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
  
  def search(search_word)
    encoded_search_word = CGI.escape(search_word)
    url = "https://duckduckgo.com/?q=#{encoded_search_word}&kl=wt-wt"
    search_results = WebClient.new.open(url, wait_element: 'ol.react-results--main', headless: true) do |driver|
      results = []
      driver.find_elements(css: 'ol.react-results--main li article').each do |li_element|
      #   puts "li_element innerHTML: #{li_element.attribute('innerHTML')}"
        title_element = li_element.find_element(css: 'h2 a span')
        url_element = li_element.find_element(css: 'h2 a')
        title = title_element.text
        url = url_element.attribute('href')
  
        results << { url: url, title: title }
      end
      results
    end
    search_results
  end

  def deep_search
    json_data = JSON.parse(File.read(@input_file))
    puts "input.jsonの内容:"
    p json_data
    puts "=========="
    puts
    puts

    results = []
    json_data["search-themes"].each do |theme_data|
      theme_name = theme_data["theme"]
      puts "テーマ名:#{theme_name}, #{(results.size + 1)}/#{json_data["search-themes"].size}"

      item_words = []
      theme_data["search-words"].each do |search_word|
        puts "Search Words: #{ (item_words.size + 1)}/#{theme_data["search-words"].size}"
        search_results = search(search_word)

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
