#!/usr/bin/env ruby
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'csv/autoparser'

data = <<CSV
this is,not,the header
the real header,is easy,to find
name,Job title,age
Jon Smith,blacksmith,55
Jimmy Johnson,farmer,34
Kimmy Kimmson,pig wrangler,29
CSV

########################################
# Indentifying the Header Row
########################################

# ID header row by CSV line number.
csv = CSV::AutoParser.new(data) {|line_number, header_row| line_number == 3 }
csv.each {|row| puts "#{row.name} is a #{row.age} year old #{row.job_title}." }
# Jon Smith is a 55 year old blacksmith.
# Jimmy Johnson is a 34 year old farmer.
# Kimmy Kimmson is a 29 year old pig wrangler.

# -OR- ID header row by column header names.
csv = CSV::AutoParser.new(data) do |line_num, header_row| 
["name", "Job title"].all? {|field| header_row.include?(field) } 
end
csv.is_a?(CSV)        # => true
table = csv.read      # => CSV::Table
table.first.name      # => "Jon Smith"
table[-1].job_title   # => "pig wrangler"


################################################
# Want to get at the data above the header row?
################################################

csv = CSV::AutoParser.new(File.expand_path("../../test/fixtures/persons.csv", __FILE__)) {|lineno, hr| lineno == 3 }
csv.pre_header_rows.each do |row|
  puts "#{row.file}(#{row.line}): #{row.inspect}"
end


########################################
# Optional Header Columns
########################################

data2 = <<CSV
name,"city  name","Job title"
"Jon Smith",Sacramento,blacksmith
"Jimmy Johnson","San Diego",farmer
"Kimmy Kimmson",Austin,"pig wrangler"
CSV

# When CSV columns are optional, specify it through options so that a NoMethodError is not raised.
def demo_optional_header_columns data
  csv = CSV::AutoParser.new(data, optional_headers: ["City Name", :age]) {|lineno, hr| hr.include? "name" }
  csv.each do |row| 
    # row.birth_date # => raises NoMethodError
    if row.city_name
      puts "#{row.name} is a #{row.age || "?"} year old #{row.job_title} living in #{row.city_name}." 
    else
      puts "#{row.name} is a #{row.age || "?"} year old #{row.job_title}." 
    end
  end
end

demo_optional_header_columns(data)
demo_optional_header_columns(data2)

