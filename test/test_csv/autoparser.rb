$LOAD_PATH.unshift File.expand_path('../..', __FILE__)
require 'minitest_helper'

describe CSV::AutoParser do

  it "it can parse a csv automatically via csv line number id" do
    table = CSV::AutoParser.new(fixture_file_path('persons.csv')) {|csv_line_number, header_row| csv_line_number == 1 }.read
    table.class.must_equal CSV::Table
    table.length.must_equal 5
    table.first["full-name"].must_equal "bob"
    table.first.full_name.must_equal "bob"
  end

  it "it can parse a csv automatically via header row id" do
    table = CSV::AutoParser.new(fixture_file_path('persons.csv'), header_converters: :symbol) do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end.read
    table.length.must_equal 3
    table.first.name.must_equal "Jon Smith"
    table.first["Job title"].must_be_nil
    table.first[:job_title].must_equal "blacksmith"
    table.first.job_title.must_equal "blacksmith"
    table[-1].age.to_i.must_equal 29
  end

  it "it will give you the rows found before the header row" do
    parser = CSV::AutoParser.new(fixture_file_path('persons.csv')) do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end
    parser.header_line_number.must_equal 3
    parser.pre_header_rows.first.last.must_equal "years of age"
    parser.pre_header_rows.last.first.must_equal "bob"
  end

  it "it will give file path, line and column number information" do
    csv_path = fixture_file_path('persons.csv')
    parser = CSV::AutoParser.new(csv_path) do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end
    line_number = 1
    parser.file_path.must_equal csv_path
    parser.pre_header_rows.each do |row|
      row.file_path.must_equal csv_path
      row.line_number.must_equal line_number
      line_number += 1
    end
    table = parser.read
    line_number = parser.header_line_number + 1
    table.each do |row|
      row.file_path.must_equal csv_path
      row.line_number.must_equal line_number
      line_number += 1
    end
  end

  it "will raise an exception if it can't find the header row" do
    lambda { CSV::AutoParser.new(fixture_file_path('persons.csv')) {|csv_line_number, header_row| csv_line_number == 0 }}.
      must_raise(CSV::AutoParser::HeaderRowNotFound)
  end

  it "will not confuse column information with another csv which is parsed simultaneously" do
    table = CSV::AutoParser.new(fixture_file_path('persons.csv')) do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end.read
    table2 = CSV::AutoParser.new(fixture_file_path('persons2.csv')) do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end.read
    table.length.must_equal 3
    table.first.name.must_equal "Jon Smith"
    table.first.job_title.must_equal "blacksmith"
    table[-1].age.to_i.must_equal 29
    table[1].job_title.must_equal "farmer"

    table2.length.must_equal 2
    table2.first.name.must_equal "Kermy Frog"
    table2.first.job_title.must_equal "frog"
    table2[-1].age.to_i.must_equal 19
  end

  it "will define methods which return nil for optional columns not present in CSV" do
    table1 = CSV::AutoParser.new(fixture_file_path('persons.csv')) do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end.read
    lambda { table1.first.my_optional_header }.must_raise(NoMethodError)
    table2 = CSV::AutoParser.new(fixture_file_path('persons.csv'), optional_headers: [:my_optional_header, "Zip Code", :name]) do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end.read
    table2.first.my_optional_header.must_be_nil
    lambda { table1.first.my_optional_header }.must_raise(NoMethodError)
    table2.first.name.must_equal "Jon Smith"
    lambda { table2.first.my_mandatory_header }.must_raise(NoMethodError)
    table2.first.zip_code.must_be_nil
    table2[-1].my_optional_header.must_be_nil
  end

  it "will pass along CSV.new options" do
    parser = CSV::AutoParser.new(fixture_file_path('persons.csv')) {|l, hr| l == 1 }
    parser.field_size_limit.must_be_nil
    parser = CSV::AutoParser.new(fixture_file_path('persons.csv'), field_size_limit: 100) {|l, hr| l == 1 }
    parser.field_size_limit.must_equal 100
  end

  it "should work with a CSV string or an IO object too" do
    input_objects = [fixture_file_path('persons.csv'), File.open(fixture_file_path('persons.csv')), File.open(fixture_file_path('persons.csv'))]
    input_objects.each do |obj|
      table = CSV::AutoParser.new(obj) do |line_num, header_row| 
        ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
      end.read
      table.length.must_equal 3
      table.first.name.must_equal "Jon Smith"
      table.first.job_title.must_equal "blacksmith"
      table[-1].age.to_i.must_equal 29
    end
  end

  it "should work just like CSV.new when not passed a block except that it can now take a file path as data too" do 
    input_objects = [
      fixture_file_path('persons.csv'), 
      File.open(fixture_file_path('persons.csv')), 
      File.read(fixture_file_path('persons.csv')), 
      StringIO.new(File.read(fixture_file_path('persons.csv')))
    ]
    input_objects.each do |obj|
      parser = CSV::AutoParser.new(obj, header_converters: :symbol, headers: :first_row)
      parser.header_line_number.must_equal 1
      parser.pre_header_rows.must_be_empty
      table = parser.read
      table.length.must_equal 5
      table.first[:fullname].must_equal "bob"
      # method names are based off of converted header names!
      table.first.fullname.must_equal "bob"
      if obj.is_a?(String) and File.exists?(obj)
        table.first.file_path.must_equal fixture_file_path('persons.csv')
      else
        table.first.file_path.must_be_nil
      end
      table.first.line_number.must_equal 2
    end
    parser = CSV::AutoParser.new(fixture_file_path('persons.csv'), header_converters: :symbol, headers: "first_col,second_col,third_col,fourth_col")
    parser.header_line_number.must_equal nil
    parser.pre_header_rows.must_be_empty
    table = parser.read
    table.length.must_equal 6
    table[0].first_col.must_equal "full-name"
    table[1].first_col.must_equal "bob"
    table[1].file_path.must_equal fixture_file_path('persons.csv')
    table[1].line_number.must_equal 2
  end

end
