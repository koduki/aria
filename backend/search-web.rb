require 'selenium-webdriver'
require 'json'
require 'cgi'

require './web-client'

class SearchWeb
  def initialize()
    @input_file = "input.json"
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

end
