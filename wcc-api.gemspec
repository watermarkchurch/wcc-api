# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wcc/api/version'

Gem::Specification.new do |spec|
  spec.name          = "wcc-api"
  spec.version       = WCC::API::VERSION
  spec.authors       = ["Watermark Dev Team"]
  spec.email         = ["dev@watermark.org"]
  spec.summary       = %q{Holds common code used in our applications that host APIs.}
  spec.description   = %q{holds common code used in our applications that host APIs.}
  spec.homepage      = "https://github.com/watermarkchurch/wcc-api"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "wcc-base"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "dotenv", "~> 0.10.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"
end
