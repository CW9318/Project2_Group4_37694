require "uri"
require "json"
require "net/http"

key = "REPLACE WITH API KEY"
url = URI("https://canvas.instructure.com/api/v1/courses?per_page=100&access_token=#{key}")

https = Net::HTTP.new(url.host, url.port)
https.use_ssl = true

request = Net::HTTP::Get.new(url)
response = https.request(request)
data = JSON.parse(response.read_body)
for element in data
  n = element["name"]
  puts n
end
