require 'httparty'
require 'dotenv/load'
require 'json'

# need carmen access token
API_TOKEN = ENV['ACCESS_TOKEN']
CANVAS_API_BASE_URL = 'https://osu.instructure.com/api/v1'

# Method to fetch active courses
def fetch_active_courses
  response = HTTParty.get(
    "#{CANVAS_API_BASE_URL}/courses",
    headers: {
      "Authorization" => "Bearer #{API_TOKEN}"
    }
  )

  # Check if the request was successful
  if response.code == 200
    courses = JSON.parse(response.body)
    display_courses(courses)
  else
    puts "Error: Unable to fetch courses. Response Code: #{response.code}"
  end
end

def display_courses(courses)
  puts "Active Courses:\n\n"
  courses.each do |course|
    # Published public courses
    if course["workflow_state"] == "available"
      puts "Course ID: #{course['id']}"
      puts "Course Name: #{course['name']}"
      puts "Course Code: #{course['course_code']}"
      puts "Course format: #{course['course_format']}"
      puts "Start Date: #{course['start_at']}"
      puts "End Date: #{course['end_at']}"
      puts "------------------------------------\n\n"
    end
  end
end

# Main program logic
fetch_active_courses