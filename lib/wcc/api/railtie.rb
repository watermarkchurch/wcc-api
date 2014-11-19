require 'wcc/api'

module WCC
  module API
    class Railtie < Rails::Railtie
      initializer 'wcc.api railtie initializer', group: :all do |app|
        ActiveSupport::Inflector.inflections(:en) do |inflect|
          inflect.acronym 'API'
        end
      end
    end
  end
end
