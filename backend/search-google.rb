require 'nokogiri'
require 'open-uri'
require 'uri'
require 'json'
require 'cgi'

def search_google(search_word)
  p search_word

  encoded_search_word = CGI.escape(search_word)
  url = "https://www.google.co.jp/search?q=#{encoded_search_word}&num=5"

  begin
    doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36'))
    p doc
    results = []

    doc.css('.yuRUbf > a').each do |link|
      url = link['href']
      p url
      title_element = link.at_css('h3')
      p title_element
      title = title_element ? title_element.text : nil
      results << { url: url, title: title }
    end
    return results
  rescue OpenURI::HTTPError => e
    puts "Error fetching Google: #{e.message}"
    return []
  rescue SocketError => e
    puts "Error fetching Google: #{e.message}"
    return []
  rescue URI::InvalidURIError => e
    puts "Invalid URL: #{url}: #{e.message}"
    return []
  rescue => e
    puts "An unexpected error occurred: #{e.message}"
    return []
  end
end

def extract_content(url)
  begin
    doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36'))
    title = doc.title
    body = doc.css('body').text.gsub(/\s+/, ' ').strip
    return { title: title, body: body }
  rescue OpenURI::HTTPError => e
    puts "Error fetching #{url}: #{e.message}"
    return { title: nil, body: nil }
  rescue SocketError => e
    puts "Error fetching #{url}: #{e.message}"
    return { title: nil, body: nil }
  rescue URI::InvalidURIError => e
    puts "Invalid URL: #{url}: #{e.message}"
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