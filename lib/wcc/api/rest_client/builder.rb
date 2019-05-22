module WCC::API
  class RestClient
    class Builder
      def initialize(klass)
        @klass = klass
      end

      def params(*params)
        @params = params.map(&:to_s)
      end

      def resource(endpoint, model:, **options)
        @resources ||= {}
        @resources[endpoint] = options.merge({
          model: model,
        })
      end

      def apply
        closed_params = (@params || []).freeze
        resources = @resources
        klass = @klass

        klass.class_exec do
          define_singleton_method :params do
            closed_params
          end

          define_singleton_method :default do
            @default ||= new
          end

          define_singleton_method :default= do |client|
            @default = client
          end

          resources.each do |(endpoint, options)|
            define_method endpoint do
              instance_variable_get("@#{endpoint}") ||
                instance_variable_set("@#{endpoint}", 
                  (self.class.const_get("Resource") || WCC::API::RestClient::Resource)
                    .new(self, endpoint, options[:model], @options.merge(options))
                )
            end
          end
        end

        resources.each do |(endpoint, options)|
          options[:model].class_exec do
            define_singleton_method :client do
              klass.default
            end

            define_singleton_method :endpoint do
              endpoint
            end

            define_singleton_method :key do
              options[:key]
            end
          end

          options[:model].send(:include, WCC::API::ActiveRecordShim)
        end
      end
    end
  end
end