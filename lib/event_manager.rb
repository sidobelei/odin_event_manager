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
  hour = date.strftime('%H').to_sym
  if popular_hours.has_key?(hour)
    popular_hours[hour] += 1
  else
    popular_hours[hour] = 1
  end
return popular_hours
end

def get_registration_days(date, popular_days)
  case date.wday
  when 0
    popular_days[:sunday] += 1 
  when 1
    popular_days[:monday] += 1
  when 2
    popular_days[:tuesday] += 1
  when 3
    popular_days[:wednesday] += 1
  when 4
    popular_days[:thursday] += 1
  when 5
    popular_days[:friday] += 1
  when 6
    popular_days[:saturday] += 1
  end
  return popular_days
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
popular_days = {
  :sunday => 0, 
  :monday => 0,
  :tuesday => 0,
  :wednesday => 0,
  :thursday => 0,
  :friday => 0,
  :saturday => 0
}

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone = clean_phone_number(row[:homephone])
  
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
  
  formatted_date = DateTime.strptime(row[:regdate], '%m/%d/%y %H:%M')
  popular_hours = get_registration_hours(formatted_date, popular_hours)
  popular_days = get_registration_days(formatted_date, popular_days)
  
  puts phone
end

puts popular_hours.sort_by {|hour, registrants| -registrants}.to_h
puts popular_days.sort_by {|day, registrants| -registrants}.to_h
