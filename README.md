# CSV::AutoParser

CSV::AutoParser automatically parses a CSV file given a user specified header row.

## Installation

    $ gem install csv-autoparser

## Usage

    require 'csv/autoparser'

    # ID header row by CSV line number.
    csv = CSV::AutoParser.new("my_file.csv") {|csv_line_number, header_row| csv_line_number == 1 }
    csv.rows.each {|row| puts row.full_name }

    # -OR- ID header row by column header names.
    csv = CSV::AutoParser.new(input_file) do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end
    puts csv.rows.first.name # => "Jon Smith"
    csv.rows.first.job_title # => "blacksmith"

## Contributing

1. Fork it ( http://github.com/bdiz/csv-autoparser/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
