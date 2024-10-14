# Output a listing of all courses you have taken at OSU, along with course number, name, code, format, start and end date.
# A listing of available syllabus of all courses you have taken. Generate an HTML file of syllabus.
# A listing of available announcements of all courses you have taken. Generate an HTML file of announcements.
# Use Google API & Search Engine ID
# Google Cloud consule & Programmable Search Engine (provided by Googlt) to search what you are interested on the internet. 
require 'httparty'
require 'dotenv/load'
require 'json'

# canvas access token and Google API key & Search Engine ID (not OAuth access token)
API_TOKEN = ENV['ACCESS_TOKEN']
CANVAS_API = 'https://osu.instructure.com/api/v1'
GOOGLE_API_KEY = ENV['GOOGLE_API_KEY']
SEARCH_ENGINE_ID = ENV['SEARCH_ENGINE_ID']
GOOGLE_CUSTOM_SEARCH_URL = 'https://www.googleapis.com/customsearch/v1'


# fetch all courses
def fetch_courses
  # record all courses
  all_courses = []
  url = "#{CANVAS_API}/courses"

  while url
    response = HTTParty.get(
      url,
      headers: {
        "Authorization" => "Bearer #{API_TOKEN}"
      }
    )

    if response.code == 200
      courses = JSON.parse(response.body)
      # append the current page of courses (Canvas api only shows about 10 courses per page)
      all_courses.concat(courses)

      # check for pagination links in the response headers
      if response.headers['link'] && response.headers['link'].include?('rel="next"')
        next_link = response.headers['link'].match(/<([^>]+)>;\s*rel="next"/)
        url = next_link ? next_link[1] : nil
      else
        # no more pages need
        url = nil
      end
    else
      puts "Error: Unable to fetch courses."
      break
    end
  end

  syllabus_list(all_courses)
  return all_courses
end

# check syllabus is available or not of input course ID
def has_syllabus?(course_id)
  response = HTTParty.get(
    "#{CANVAS_API}/courses/#{course_id}?include[]=syllabus_body",
    headers: {
      "Authorization" => "Bearer #{API_TOKEN}"
    }
  )

  if response.code == 200
    course = JSON.parse(response.body)
    syllabus_body = course['syllabus_body']
    
    # true if syllabus exist
    return !syllabus_body.nil?
  else
    puts "Error: Unable to fetch syllabus for course ID #{course_id}."
    return false
  end
end

# output list of courses with available syllabus
def syllabus_list(courses)
  coursesWithSyllabus = []

  puts "All Courses:\n\n"
  
  courses.each do |course|
    # output all courses
    if course["workflow_state"] == "available"
      puts "Course ID: #{course['id']}"
      puts "Course Name: #{course['name']}"
      puts "Course Code: #{course['course_code']}"
      puts "Course format: #{course['course_format']}"
      puts "Start Date: #{course['start_at']}"
      puts "End Date: #{course['end_at']}"
      puts "------------------------------------\n\n"

      # check the course has syllabus or not
      if has_syllabus?(course['id'])
        # store both the course ID and name
        coursesWithSyllabus << { id: course['id'], name: course['name'] }
      end
    end
  end

  # output if available
  unless coursesWithSyllabus.empty?
    puts "\nCourses with Available Syllabus:\n\n"
    coursesWithSyllabus.each do |course|
      puts "Course ID: #{course[:id]} - Course Name: #{course[:name]}"
    end
    puts "------------------------------------\n\n"
  else
    puts "\nNo courses have a syllabus available.\n\n"
  end
end

# fetch syllabus of specific course ID and save
def fetch_syllabus(course_id)
  response = HTTParty.get(
    "#{CANVAS_API}/courses/#{course_id}?include[]=syllabus_body",
    headers: {
      "Authorization" => "Bearer #{API_TOKEN}"
    }
  )

  if response.code == 200
    course = JSON.parse(response.body)
    syllabus_body = course['syllabus_body']
    
    if syllabus_body
      # write syllabus to the input course ID file
      File.open("syllabus_#{course_id}.html", 'w') do |file|
        file.write(syllabus_body)
      end
      puts "Syllabus saved to syllabus_#{course_id}.html\n\n"
    else
      puts "Syllabus is not available for your input course ID.\n\n"
    end
  else
    puts "Error: Unable to fetch syllabus for course ID #{course_id}."
  end
end

# fetch syllabus of specific course ID and save
def fetch_announcements(course_id)
  response = HTTParty.get(
    "#{CANVAS_API}/courses/#{course_id}/discussion_topics?only_announcements=true",
    headers: {
      "Authorization" => "Bearer #{API_TOKEN}"
    }
  )

  if response.code == 200
    announcements = JSON.parse(response.body)
    
    if announcements.any?
      return announcements
    else
      return nil
    end
  else
    puts "Error: Unable to fetch announcements for course ID #{course_id}."
    return nil
  end
end

# output list of courses with available announcements
def announcements_list(courses)
  courses_with_announcements = []

  puts "\nChecking for courses with available announcements. (It will take some time)\n\n"
  
  courses.each do |course|
    if course["workflow_state"] == "available"
      announcements = fetch_announcements(course['id'])
      if announcements
        courses_with_announcements << { id: course['id'], name: course['name'] }
      end
    end
  end

  unless courses_with_announcements.empty?
    puts "\nCourses with Available Announcements:\n\n"
    courses_with_announcements.each do |course|
      puts "Course ID: #{course[:id]} - Course Name: #{course[:name]}"
    end
    puts "------------------------------------\n\n"
  else
    puts "No courses have announcements available.\n\n"
  end
end

# generate html with announcements
def html_announcement(course_id, course_name, announcements)
  File.open("announcements_#{course_id}.html", 'w') do |file|
    file.write("<html><body><h1>Announcements for #{course_name}</h1>")
    announcements.each do |announcement|
      file.write("<h2>#{announcement['title']}</h2>")
      file.write("<p>#{announcement['message']}</p>")
      file.write("<p><strong>Posted at:</strong> #{announcement['posted_at']}</p>")
      file.write("<hr>")
    end
    file.write("</body></html>")
  end
  puts "Announcements saved to announcements_#{course_id}.html\n\n"
end

# fetch info&images using Google Custom Search API
def fetch_images(input, nums)
  response = HTTParty.get(
    GOOGLE_CUSTOM_SEARCH_URL,
    query: {
      key: GOOGLE_API_KEY,
      cx: SEARCH_ENGINE_ID,
      # key words to fetch
      q: input,
      searchType: 'image',
      # number of images to fetch
      num: nums
    }
  )
  # Check if the request was successful
  if response.code == 200
    images = JSON.parse(response.body)['items']
    return images
  else
    puts "Error: Unable to fetch images."
    return []
  end
end

def html_search(images, item)
  html_content = <<-HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>#{item.capitalize}</title>
      <style>
        .image-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(100px, 1fr));
          gap: 20px;
        }
        .image-item {
          text-align: center;
        }
        .image-item img {
          border-radius: 10px;
          width: 100%;
          height: auto;
        }
      </style>
    </head>
    <body>
      <h1>#{item.capitalize}</h1>
      <div class="image-grid">
  HTML

  images.each do |image|
    html_content += <<-HTML
      <div class="image-item">
        <img src="#{image['link']}" alt="#{item}">
        <p>#{image['title']}</p>
      </div>
    HTML
  end

  html_content += <<-HTML
      </div>
    </body>
    </html>
  HTML

  filename = "#{item.downcase}.html"

  # save to file
  File.open(filename, 'w') { |file| file.write(html_content) }
  puts "HTML page generated: #{filename}"
end

# main program
def main
  courses = fetch_courses

  puts "Input the course ID you are interested in for the syllabus: "
  course_id = gets.chomp.to_s

  fetch_syllabus(course_id)

  announcements_list(courses)

  puts "Input the course ID you are interested in for the announcements: "
  announcement_course_id = gets.chomp.to_s

  # fetch announcements if available
  course = courses.find { |c| c['id'].to_s == announcement_course_id }
  if course
    course_name = course['name']
    announcements = fetch_announcements(announcement_course_id)

    if announcements
      puts "\nAnnouncements are available for this course."
      puts "Would you like to save the announcements? (y/n)"
      save_announcements = gets.chomp.downcase

      if save_announcements == 'y'
        html_announcement(announcement_course_id, course_name, announcements)
      else
        puts "You chose not to save the announcements."
      end
    else
      puts "No announcements available for this course.\n\n"
    end
  else
    puts "Invalid course ID.\n\n"
  end
  # ask check or not
  puts "Based on the courses syllabus and announcements"
  puts "Would you like to search info and images on the internet? (y/n)"
  search_check = gets.chomp.downcase

  if search_check == 'y'
    puts "Input some key words you want to search for: "
    item = gets.chomp
    puts "How many images and information do you want to generate: "
    nums = gets.chomp.to_i

    images = fetch_images(item, nums)

    if images.any?
      html_search(images, item)
    else
      puts "No images found or unable to fetch data."
    end
  else
    puts "You chose not to search."
  end
end

 main