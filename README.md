# CSV::AutoParser

CSV::AutoParser automatically parses a CSV file given a user specified header row.

## Installation

    $ gem install csv-autoparser

## Usage

    require 'csv/autoparser'

    # ID header row by CSV line number.
    csv = CSV::AutoParser.new("persons.csv") {|csv_line_number, header_row| csv_line_number == 1 }
    csv.rows.each {|row| puts row.full_name }

    # -OR- ID header row by column header names.
    csv = CSV::AutoParser.new("persons.csv") do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end
    csv.rows.first.name      # => "Jon Smith"
    csv.rows.first.job_title # => "blacksmith"

## More usage options...

    # Parsing multiple CSVs and getting NoMethodError for optional column headers?
    csv = CSV::AutoParser.new("persons.csv", optional_headers: ["State", "Zip Code"]) {|l, hr| l == 1 }
    csv.rows.first.name      # => "bob"
    csv.rows.first.state     # => nil
    csv.rows.first.zip_code  # => nil
    csv.rows.first.nickname  # => raises NoMethodError

## Contributing

1. Fork it ( http://github.com/bdiz/csv-autoparser/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
