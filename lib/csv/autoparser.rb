require "csv"
require "csv/autoparser/version"

class CSV

  class Row
    alias_method :orig_initialize, :initialize
    # Defines method style accessors based on header row names.
    def initialize(*args)
      orig_initialize(*args)
      if field_row?
        headers.each do |h|
          define_singleton_method(CSV::AutoParser.convert_header_to_method_name(h)) { fetch(h) }
        end
      end
    end
  end

  class AutoParser < CSV

    # This is the method called by AutoParser to turn header names into legal method names.
    # Redefine as necessary.
    def self.convert_header_to_method_name header
      header.to_s.downcase.strip.gsub(/\s+/, '_').gsub(/-+/, '_').gsub(/[^\w]/, '').to_sym
    end

    # The rows found before the header row are paired with file and line information. These
    # objects are available through CSV::AutoParser#pre_header_rows.
    class PreHeaderRow < Array
      attr_reader :file, :line
      def self.create original_row, file, line
        row = PreHeaderRow.new(original_row)
        row.instance_eval { @file = file; @line = line }
        return row
      end
    end

    class HeaderRowNotFound < RuntimeError; end

    attr_reader :pre_header_rows, :header_line_number

    # +data+ can be path of CSV file in addition to a CSV String or an IO object like CSV.new.
    # All CSV.new options are supported via +opts+. If an +&is_header+ block is provided, it 
    # takes precedence over the CSV.new +:headers+ option. A +:optional_headers+ option has
    # been added for specifying headers that may not be present in the CSV, but you do not want
    # a NoMethodError to raise when accessing a field using the header method style accessor.
    def initialize data, opts={}, &is_header
      @header_line_number = nil
      @pre_header_rows = []
      @optional_headers = [opts.delete(:optional_headers)].flatten.compact
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
        data_io = StringIO.new(data_io.read)
        super(data_io, opts.merge(:headers => true))
      else
        @header_line_number = 1 if opts[:headers] == :first_row or opts[:headers] == true
        super(data, opts)
      end
    end

    alias_method :orig_shift, :shift

    # Overriden to add methods for optional headers which were not present in the CSV.
    def shift
      row = orig_shift
      [@optional_headers].flatten.compact.each do |h|
        method_name = self.class.convert_header_to_method_name(h)
        unless row.respond_to? method_name
          row.define_singleton_method(method_name) {nil}
        end
      end
      return row
    end

  end
end
