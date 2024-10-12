require 'httparty'
require 'dotenv/load'
require 'nokogiri'
require 'json'

# token reads your access token from the .env so that it won't leak.
# url holds the link the data from
token = "Bearer #{ENV['CANVAS_TOKEN']}"
url = "https://osu.instructure.com/api/v1/announcements"
courseID = "171872"

query_params = {
    context_codes: ["course_#{courseID}"],  # Required parameter (specify course context)
}

response = HTTParty.get(
        url,
        headers: {'Authorization' => "#{token}"},
        query: query_params
)

if response.code == 200
        # We entered the site
        announcements = JSON.parse(response.body)

        # list all announcements.
        puts "#{announcements.size} Announcements"
        announcements.each do |a|
            # Preprocess the message to remove HTML tags
            message = Nokogiri::HTML(a['message']).text
                        puts "Course ID: #{a['context_code']}"
                        puts "Title: #{a['title']}"
                        puts "Message: #{message.strip}"
                        puts "==============================\n"
        end
else
        # Failed to fetch any data
        puts "Error #{response.code}: cannot access announcements"
end
