require "uri"
require "json"
require "net/http"
require_relative "course_search" 
require 'dotenv/load'


key = ENV['CANVAS_API_KEY']
url = URI("https://canvas.instructure.com/api/v1/courses?per_page=100&access_token=#{key}")

https = Net::HTTP.new(url.host, url.port)
https.use_ssl = true

request = Net::HTTP::Get.new(url)
response = https.request(request)
data = JSON.parse(response.read_body)

puts "Please enter the term (e.g., AU24, SP23, SU21):"
user_term = gets.chomp

#validates user input for term
if valid_term?(user_term)
  user_term = user_term.upcase
  get_courses_by_term(data, user_term)
end