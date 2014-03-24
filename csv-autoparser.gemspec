# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'csv/autoparser/version'

Gem::Specification.new do |spec|
  spec.name          = "csv-autoparser"
  spec.version       = CSV::AutoParser::VERSION
  spec.authors       = ["Ben Delsol"]
  spec.email         = [] # contact me via github (username: bdiz)
  spec.summary       = %q{Can parse a CSV file automatically given a user specified header row.}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
