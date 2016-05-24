# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_tsv/version'

Gem::Specification.new do |spec|
  spec.name          = "active_tsv"
  spec.version       = ActiveTsv::VERSION
  spec.authors       = ["ksss"]
  spec.email         = ["co000ri@gmail.com"]

  spec.summary       = "A Class of Active record pattern for TSV/CSV"
  spec.description   = "A Class of Active record pattern for TSV/CSV"
  spec.homepage      = "https://github.com/ksss/active_tsv"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{_test.rb}) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport"
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rgot"
end
