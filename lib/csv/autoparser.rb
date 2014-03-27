require "csv"
require "csv/autoparser/version"

class CSV
  class AutoParser

    class Row < Array
      attr_reader :csv_file, :csv_line
      def self.create original_row, file, line
        row = Row.new(original_row)
        row.instance_eval { @csv_file = file; @csv_line = line }
        return row
      end
    end

    class HeaderRowNotFound < RuntimeError; end

    attr_reader :pre_header_rows, :rows

    def initialize file, &is_header
      map = {}
      csv_line_number = 0
      @rows = []
      @pre_header_rows = []
      CSV.foreach(file) do |row| 
        csv_line_number += 1
        if map.empty?
          if is_header.call(csv_line_number, row)
            row.each_index {|index| map[row[index]] = index } 
          else
            @pre_header_rows << Row::create(row, file, csv_line_number)
          end
        else
          @rows << Row::create(row, file, csv_line_number)
          map.each_pair do |column_name, column_offset|
            @rows.last.define_singleton_method(column_to_method_name(column_name)) { self[column_offset] }
          end
        end
      end
      raise HeaderRowNotFound, "Could not find header row in #{file}." if map.empty?
    end

    def column_to_method_name name
      name.downcase.strip.gsub(/\s+/, '_').gsub(/-+/, '_').gsub(/[^\w]/, '')
    end

  end
end
