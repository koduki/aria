require 'selenium-webdriver'
require 'json'
require 'cgi'

def search_google(search_word)
  p search_word

  encoded_search_word = CGI.escape(search_word)
  url = "https://duckduckgo.com/?q=#{encoded_search_word}&kl=wt-wt"

  begin
    driver = Selenium::WebDriver.for :edge
    driver.get(url)

    results = []
    driver.find_elements(css: 'div.results--main div.nrn-react-div a.nrn-ext-link').each do |link_element|
      url = link_element.attribute('href')
      p url
      title_element = link_element.find_element(css: 'span')
      p title_element
      title = title_element ? title_element.text : nil
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
p json_data
puts "=========="
puts
puts

results = {}
json_data["search-themes"].each do |theme_data|
  theme_name = theme_data["theme"]
  p theme_name
  results[theme_name] = {}
  theme_data["search-words"].each do |search_word|
    search_results = search_google(search_word)
    results[theme_name][search_word] = []

    search_results.each do |result|
      if result[:url]
        content = extract_content(result[:url])
        results[theme_name][search_word] << {
          url: result[:url],
          title: content[:title],
          body: content[:body]
        }
      end
    end
  end
end

puts JSON.pretty_generate(results)
