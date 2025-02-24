require 'sinatra'
require 'json'
require_relative './lib/aria'

set :aria, Aria.new

post '/api/chat' do
  content_type :json
  request_body = JSON.parse(request.body.read)
  text = request_body['text']
  
  settings.aria.chat(text)
end
