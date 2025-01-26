require 'selenium-webdriver'
require 'json'
require 'cgi'

class SearchWeb
  def initialize()
    @input_file = "input.json"
  end

  def search_google(search_word)
    puts "search_google 関数開始: search_word = #{search_word}"
    encoded_search_word = CGI.escape(search_word)
    url = "https://duckduckgo.com/?q=#{encoded_search_word}&kl=wt-wt"
    puts "DuckDuckGo URL: #{url}"

    begin
      wait = Selenium::WebDriver::Wait.new(timeout: 10) # 最大10秒待機
      driver = Selenium::WebDriver.for :edge
      driver.get(url)
      puts "DuckDuckGoのページにアクセスしました: #{url}"

      results = []
      begin
        puts "'ol.react-results--main'要素の検索を開始"
        wait.until { driver.find_element(css: 'ol.react-results--main') }
        puts "'ol.react-results--main'要素が見つかりました"
      rescue Selenium::WebDriver::Error::TimeoutError => e
        puts "タイムアウトエラー: 'ol.react-results--main'要素が見つかりませんでした"
        puts "エラー詳細: #{e.message}"
        driver.quit
        return []
      end

      driver.find_elements(css: 'ol.react-results--main li article').each do |li_element|
      #   puts "li_element innerHTML: #{li_element.attribute('innerHTML')}"
        title_element = li_element.find_element(css: 'h2 a span')
        url_element = li_element.find_element(css: 'h2 a')
        title = title_element.text
        url = url_element.attribute('href')
   
        results << { url: url, title: title }
      end
      driver.quit

      return results
    rescue Selenium::WebDriver::Error::WebDriverError => e
      puts "Selenium WebDriver エラー: #{e.message}"
      return []
    rescue => e
      puts "予期しないエラーが発生しました: #{e.message}"
      return []
    end
  end

  def extract_content(url)
    begin
      options = Selenium::WebDriver::Edge::Options.new
      options.add_argument('--headless')
      driver = Selenium::WebDriver.for :edge, options: options
      driver.get(url)

      title = driver.title
      body = driver.find_element(tag_name: 'body').text.gsub(/\s+/, ' ').strip

      driver.quit
      return { title: title, body: body }
    rescue Selenium::WebDriver::Error::WebDriverError => e
      puts "Error fetching #{url} with Selenium: #{e.message}"
      return { title: nil, body: nil }
    rescue => e
      puts "An unexpected error occurred while fetching #{url}: #{e.message}"
      return { title: nil, body: nil }
    end
  end

  def search
    json_data = JSON.parse(File.read(@input_file))
    puts "input.jsonの内容:"
    p json_data
    puts "=========="
    puts
    puts

    results = []
    json_data["search-themes"].each do |theme_data|
      theme_name = theme_data["theme"]
      puts "テーマ名:"
      p theme_name
      # results[theme_name] = {}
      item_words = []
      theme_data["search-words"].each do |search_word|
        puts "  検索ワード:"
        p search_word
        search_results = search_google(search_word)
        # puts "    検索結果:"
        # p search_results

        puts "    コンテンツ抽出開始"

        item_contents = []
        search_results.take(3).each do |result|
          if result[:url]
            puts "      URL:"
            p result[:url]
            content = extract_content(result[:url])
            puts "        コンテンツ抽出結果:"
            item_contents << {
              url: result[:url],
              title: content[:title],
              body: content[:body]
            }
          end
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
