def valid_term?(term)
    # Regular expression to check format: AU, SP, SU followed by 2 digits
    regex = /^\s*(AU|SP|SU)\d{2}$/i
    if term.match(regex)
      return true
    else
      puts "Invalid term format. Please enter a term in the format AU/SP/SU followed by 2 digits for the year (e.g., AU24)."
      return false
    end
  end
  
  def get_courses_by_term(data, term)
    found = false
    data.each do |element|
      if element["name"] && element["name"].include?(term)
        puts "Course in #{term}: #{element['name']}"
        found = true
      end
    end
    puts "No courses found for the term #{term}" unless found
  end
  