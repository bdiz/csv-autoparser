$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'csv/autoparser'

require 'minitest/spec'
require 'minitest/autorun'

def fixture_file_path file_name
  File.join(File.expand_path('../fixtures', __FILE__), file_name)
end

