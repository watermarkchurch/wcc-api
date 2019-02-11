# frozen_string_literal: true

SPEC_DIR = File.dirname(__FILE__)
FIXTURES_DIR = File.join(SPEC_DIR, 'fixtures')

$LOAD_PATH.unshift File.join(SPEC_DIR, '..', 'lib')
$LOAD_PATH.unshift SPEC_DIR

require 'dotenv'
Dotenv.load

require 'webmock/rspec'
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

require 'wcc/api'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.include FixturesHelper
end
