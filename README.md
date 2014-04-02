# CSV::AutoParser

CSV::AutoParser automatically parses a CSV file given a user specified header row and
adds method style accessors to the CSV::Row data. 

All functionality of the standard Ruby CSV class is accessible since CSV::AutoParser
inherits from CSV. CSV::AutoParser objects behave just like CSV objects when not
provided a block (though method style accessors will still be avaliable on CSV::Row
objects).

## Installation

    $ gem install csv-autoparser

## Usage

```ruby
    require 'csv/autoparser'

    data = <<CSV
    "this is",not,"the header"
    "the real header","is easy","to find"
    name,"Job title",age
    "Jon Smith",blacksmith,55
    "Jimmy Johnson",farmer,34
    "Kimmy Kimmson","pig wrangler",29
    CSV

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
```

More usage examples can be seen in examples/.

## Contributing

1. Fork it ( http://github.com/bdiz/csv-autoparser/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
