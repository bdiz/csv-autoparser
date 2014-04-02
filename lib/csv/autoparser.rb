require "csv"
require "csv/autoparser/version"

class CSV

  class Row
    alias_method :orig_initialize, :initialize
    def initialize(*args)
      orig_initialize(*args)
      if field_row?
        headers.each do |h|
          define_singleton_method(convert_header_to_method_name(h)) { fetch(h) }
        end
      end
    end
    def convert_header_to_method_name header
      CSV::AutoParser.convert_header_to_method_name header
    end
  end

  class AutoParser < CSV

    def self.convert_header_to_method_name header
      header.to_s.downcase.strip.gsub(/\s+/, '_').gsub(/-+/, '_').gsub(/[^\w]/, '').to_sym
    end

    # CSV::Row methods will be defined to return nil. If an actual header column exists
    # the value in this column will override the nil return value/method.
    def self.define_optional_headers *headers
      [headers].flatten.compact.each do |h|
        method_name = convert_header_to_method_name(h)
        if CSV::Row.instance_methods.include? method_name
          raise "Cannot define optional header with the same name as an existing CSV::Row method: #{method_name}"
        end
        CSV::Row.instance_eval { define_method(method_name) { nil } }
      end
    end

    class PreHeaderRow < Array
      attr_reader :file, :line_number
      def self.create original_row, file, line_number
        row = PreHeaderRow.new(original_row)
        row.instance_eval { @file = file; @line_number = line_number }
        return row
      end
    end

    class HeaderRowNotFound < RuntimeError; end

    attr_reader :pre_header_rows, :header_line_number

    # +data+ can be path of CSV file in addition to String and IO object like CSV.new.
    # All CSV.new options are supported via +opts+ with these nuances:
    #   * If an +is_header+ block is provided, it overrides the CSV.new +:headers+ option.
    def initialize data, opts={}, &is_header
      @header_line_number = nil
      @pre_header_rows = []
      if data.is_a?(String) and File.exists?(data)
        file = data
        data = File.open(data) 
      end
      if block_given?
        data_io = if data.is_a?(IO)
                    data
                  elsif data.is_a?(String)
                    StringIO.new(data)
                  else
                    raise ArgumentError, "data must be a path to a CSV file, a CSV formatted String, or an IO object."
                  end
        header_pos = data_io.pos
        csv_line_number = 0
        header_finder = CSV.new(data_io, opts.merge(:headers => false)).each do |row| 
          csv_line_number += 1
          if is_header.call(csv_line_number, row)
            @header_line_number = csv_line_number
            break
          else
            @pre_header_rows << CSV::AutoParser::PreHeaderRow.create(row, file, csv_line_number)
          end
          header_pos = data_io.pos
        end
        raise HeaderRowNotFound, "Could not find header row#{file ? " in #{file}" : "" }." if @header_line_number.nil?
        data_io.seek header_pos
        super(data_io, opts.merge(:headers => true))
      else
        @header_line_number = 1 if opts[:headers] == :first_row or opts[:headers] == true
        super(data, opts)
      end
    end

  end
end
