$LOAD_PATH.unshift File.expand_path('../..', __FILE__)
require 'minitest_helper'

describe CSV::AutoParser do

  it "it can parse a csv automatically via csv line number id" do
    csv = CSV::AutoParser.new(fixture_file_path('persons.csv')) {|csv_line_number, header_row| csv_line_number == 1 }
    csv.rows.length.must_equal 5
    csv.rows.first.full_name.must_equal "bob"
  end

  it "it can parse a csv automatically via header row id" do
    csv = CSV::AutoParser.new(fixture_file_path('persons.csv')) do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end
    csv.rows.length.must_equal 3
    csv.rows.first.name.must_equal "Jon Smith"
    csv.rows.first.job_title.must_equal "blacksmith"
    csv.rows.last.age.to_i.must_equal 29
  end

  it "it will give you the rows found before the header row" do
    csv = CSV::AutoParser.new(fixture_file_path('persons.csv')) do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end
    csv.pre_header_rows.first.last.must_equal "years of age"
    csv.pre_header_rows.last.first.must_equal "bob"
    File.basename(csv.pre_header_rows.last.csv_file).must_equal "persons.csv"
    csv.pre_header_rows.last.csv_line.must_equal 2
  end

  it "will raise an exception if it can't find the header row" do
    lambda { CSV::AutoParser.new(fixture_file_path('persons.csv')) {|csv_line_number, header_row| csv_line_number == 0 }}.
      must_raise(CSV::AutoParser::HeaderRowNotFound)
  end

  it "will not confuse column information with another csv which is parsed simultaneously" do
    csv = CSV::AutoParser.new(fixture_file_path('persons.csv')) do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end
    csv2 = CSV::AutoParser.new(fixture_file_path('persons2.csv')) do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end
    csv.rows.length.must_equal 3
    csv.rows.first.name.must_equal "Jon Smith"
    csv.rows.first.job_title.must_equal "blacksmith"
    csv.rows.last.age.to_i.must_equal 29
    csv.rows[1].job_title.must_equal "farmer"
    csv.rows[1].csv_line.must_equal 5

    csv2.rows.length.must_equal 2
    csv2.rows.first.name.must_equal "Kermy Frog"
    csv2.rows.first.job_title.must_equal "frog"
    csv2.rows.last.age.to_i.must_equal 19
    File.basename(csv2.rows.first.csv_file).must_equal "persons2.csv"
  end

  it "will define methods which return nil for optional columns not present in CSV" do
    csv = CSV::AutoParser.new(fixture_file_path('persons.csv')) do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end
    lambda { csv.my_optional_header }.must_raise(NoMethodError)
    csv = CSV::AutoParser.new(fixture_file_path('persons.csv'), optional_headers: :my_optional_header) do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end
    csv.rows.first.my_optional_header.must_be_nil
    csv = CSV::AutoParser.new(fixture_file_path('persons.csv'), optional_headers: [:my_optional_header, "Zip Code"]) do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end
    csv.rows.first.name.must_equal "Jon Smith"
    lambda { csv.rows.first.my_mandatory_header }.must_raise(NoMethodError)
    csv.rows.first.zip_code.must_be_nil
    csv.rows.last.my_optional_header.must_be_nil
  end

end
