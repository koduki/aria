require 'selenium-webdriver'
require 'json'
require 'cgi'

def search_google(search_word)
  p search_word

  encoded_search_word = CGI.escape(search_word)
  url = "https://duckduckgo.com/?q=#{encoded_search_word}&kl=wt-wt"

  begin
    wait = Selenium::WebDriver::Wait.new(timeout: 10) # 最大10秒待機
    driver = Selenium::WebDriver.for :edge
    driver.get(url)
    puts "DuckDuckGoのページにアクセスしました: #{url}"

    results = []
    begin
      wait.until { driver.find_element(css: 'ol.react-results--main') }
      puts "'ol.react-results--main'要素が見つかりました"
    rescue Selenium::WebDriver::Error::TimeoutError => e
      puts "タイムアウトエラー: 'ol.react-results--main'要素が見つかりませんでした"
      puts "エラー詳細: #{e.message}"
      driver.quit
      return []
    end

    driver.find_elements(css: 'ol.react-results--main li').each do |li_element|
        puts "item: #{li_element.attribute('innerHTML')}"
      title_element = li_element.find_element(css: 'span')
      url_element = li_element.find_element(css: 'a')
      title = title_element.text
      url = url_element.attribute('href')
      puts "タイトル: #{title}"
      puts "URL: #{url}"
      results << { url: url, title: title }
    end
    driver.quit
    return results
  rescue Selenium::WebDriver::Error::WebDriverError => e
    puts "Error fetching DuckDuckGo with Selenium: #{e.message}"
    return []
  rescue => e
    puts "An unexpected error occurred: #{e.message}"
    return []
  end
end

def extract_content(url)
  begin
    driver = Selenium::WebDriver.for :edge
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

json_data = JSON.parse(File.read('input.json'))
puts "input.jsonの内容:"
p json_data
puts "=========="
puts
puts

results = {}
json_data["search-themes"].each do |theme_data|
  theme_name = theme_data["theme"]
  puts "テーマ名:"
  p theme_name
  results[theme_name] = {}
  theme_data["search-words"].each do |search_word|
    puts "  検索ワード:"
    p search_word
    search_results = search_google(search_word)
    puts "    検索結果:"
    p search_results
    results[theme_name][search_word] = []

    search_results.each do |result|
      if result[:url]
        puts "      URL:"
        p result[:url]
        content = extract_content(result[:url])
        puts "        コンテンツ抽出結果:"
        p content
        results[theme_name][search_word] << {
          url: result[:url],
          title: content[:title],
          body: content[:body]
        }
      end
    end
  end
end

puts "=========="
puts "最終結果:"
puts JSON.pretty_generate(results)
puts "=========="
