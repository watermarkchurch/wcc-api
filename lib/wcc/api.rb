# frozen_string_literal: true

require 'wcc'
require 'wcc/api/version'

module WCC::API
  PROJECT_ROOT = File.expand_path(File.join(__FILE__, '..', '..', '..'))
end

require 'wcc/api/railtie' if defined?(Rails)

require 'wcc/api/base_query'
require 'wcc/api/json'
require 'wcc/api/controller_helpers'
require 'wcc/api/rest_client'
require 'wcc/api/view_helpers'
