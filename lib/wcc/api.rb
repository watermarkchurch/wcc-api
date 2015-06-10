require 'wcc'
require 'wcc/api/version'

module WCC
  module API
    PROJECT_ROOT = File.expand_path(File.join(__FILE__, '..', '..', '..'))
  end
end

if defined?(Rails)
  require 'wcc/api/railtie'
end

require 'wcc/api/base_query'
require 'wcc/api/json'
require 'wcc/api/controller_helpers'
require 'wcc/api/view_helpers'

