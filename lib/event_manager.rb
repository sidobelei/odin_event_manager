require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  cleaned_number = phone_number.gsub(/[+.()\-\s]/, "")
  case cleaned_number.length
  when 10
  when 11
    if cleaned_number[0] == "1"
      cleaned_number = cleaned_number[1..10]
    else
      return "Invalid Number #{phone_number}"
    end
  else
    return "Invalid Number #{phone_number}"
  end
  return cleaned_number.gsub(/^([0-9]{3})([0-9]{3})/, '(\1)' + ' \2-') 
end

def get_registration_hours(date, popular_hours)
  hour = DateTime.strptime(date, '%m/%d/%y %H:%M').strftime('%H').to_sym
  if popular_hours.has_key?(hour)
    popular_hours[hour] += 1
  else
    popular_hours[hour] = 1
  end
return popular_hours
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
popular_hours = {}

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone = clean_phone_number(row[:homephone])
  popular_hours = get_registration_hours(row[:regdate], popular_hours)
  
  puts phone

  #form_letter = erb_template.result(binding)
  #save_thank_you_letter(id,form_letter)
end
puts popular_hours.sort_by {|hour, registrants| -registrants}.to_h
