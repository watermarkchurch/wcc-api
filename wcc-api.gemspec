# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wcc/api/version'

Gem::Specification.new do |spec|
  spec.name          = 'wcc-api'
  spec.version       = WCC::API::VERSION
  spec.authors       = ['Watermark Dev']
  spec.email         = ['dev@watermark.org']
  spec.summary =
    spec.description = 'Holds common code used in our applications that host ' \
    'APIs and those that consume them.'
  spec.homepage      = 'https://github.com/watermarkchurch/wcc-api'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*'] + %w[LICENSE.txt README.md wcc-api.gemspec]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'wcc-base'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'dotenv', '~> 0.10.0'
  spec.add_development_dependency 'faraday', '~> 0.9'
  spec.add_development_dependency 'guard', '~> 2.15'
  spec.add_development_dependency 'guard-rspec', '~> 4.7'
  spec.add_development_dependency 'guard-rubocop', '~> 1.3'
  spec.add_development_dependency 'httplog', '~> 1.0'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '~> 3.3'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.3.0'
  spec.add_development_dependency 'rubocop', '0.69.0'
  spec.add_development_dependency 'typhoeus', '~> 1.3'
  spec.add_development_dependency 'webmock', '~> 3.0'
end
