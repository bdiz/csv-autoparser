$LOAD_PATH.unshift File.expand_path('../..', __FILE__)
require 'minitest_helper'

describe CSV::AutoParser do

  def input_file 
    fixture_file_path('persons.csv')
  end

  it "it can parse a csv automatically via csv line number id" do
    csv = CSV::AutoParser.new(input_file) {|csv_line_number, header_row| csv_line_number == 1 }
    csv.rows.length.must_equal 4
    csv.rows.first.full_name.must_equal "name"
  end

  it "it can parse a csv automatically via header row id" do
    csv = CSV::AutoParser.new(input_file) do |line_num, header_row| 
      ["name", "Job title"].all? {|cell| header_row.include?(cell) } 
    end
    csv.rows.length.must_equal 3
    csv.rows.first.name.must_equal "Jon Smith"
    csv.rows.first.job_title.must_equal "blacksmith"
    csv.rows.last.age.to_i.must_equal 29
  end

  it "will raise an exception if it can't find the header row" do
    lambda { CSV::AutoParser.new(input_file) {|csv_line_number, header_row| csv_line_number == 0 }}.
      must_raise(CSV::AutoParser::HeaderRowNotFound)
  end

end
