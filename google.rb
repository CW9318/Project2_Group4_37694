require 'httparty'
require 'dotenv/load'
require 'json'

# need Google API key & Search Engine ID
GOOGLE_API_KEY = ENV['GOOGLE_API_KEY']
SEARCH_ENGINE_ID = ENV['SEARCH_ENGINE_ID']
GOOGLE_CUSTOM_SEARCH_URL = 'https://www.googleapis.com/customsearch/v1'

# Fetch images using Google Custom Search API
def fetch_images
  response = HTTParty.get(
    GOOGLE_CUSTOM_SEARCH_URL,
    query: {
      key: GOOGLE_API_KEY,
      cx: SEARCH_ENGINE_ID,
      # key words to fetch
      q: 'cat',
      searchType: 'image',
      # number of images to fetch
      num: 10
    }
  )

  # Check if the request was successful
  if response.code == 200
    images = JSON.parse(response.body)['items']
    return images
  else
    puts "Error: Unable to fetch images. Response Code: #{response.code}"
    return []
  end
end

def generate_html(images)
  html_content = <<-HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Squirrel Pictures</title>
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
      <h1>Pictures</h1>
      <div class="image-grid">
  HTML

  images.each do |image|
    html_content += <<-HTML
      <div class="image-item">
        <img src="#{image['link']}" alt="Squirrel">
        <p>#{image['title']}</p>
      </div>
    HTML
  end

  html_content += <<-HTML
      </div>
    </body>
    </html>
  HTML

  # Save to file
  File.open("pictures.html", 'w') { |file| file.write(html_content) }
  puts "HTML page generated: pictures.html"
end

# main
def main
  images = fetch_images

  if images.any?
    generate_html(images)
  else
    puts "No images found or unable to fetch data."
  end
end

main