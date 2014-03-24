require "csv"
require "csv/autoparser/version"

class CSV
  class AutoParser
    class Row

      def self.define_methods map
        map.each_pair do |column_name, column_offset|
          define_method(column_to_method_name(column_name)) { @row[column_offset] }
        end
      end

      def self.column_to_method_name name
        name.downcase.strip.gsub(/\s+/, '_').gsub(/-+/, '_').gsub(/[^\w]/, '')
      end

      def initialize row
        @row = row
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
            Row.define_methods(map)
          else
            @pre_header_rows << row
          end
        else
          @rows << Row.new(row)
        end
      end
      raise HeaderRowNotFound, "Could not find header row in #{file}." if map.empty?
    end

  end
end
