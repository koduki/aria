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