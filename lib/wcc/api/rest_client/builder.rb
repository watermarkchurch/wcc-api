module WCC::API
  class RestClient
    class Builder
      def initialize(klass)
        @klass = klass
      end

      def params(*params)
        @params = params.map(&:to_s)
      end

      def resource(key, model)
        @resources ||= {}
        @resources[key] = model
      end

      def apply
        closed_params = (@params || []).freeze
        resources = @resources

        @klass.class_exec do
          define_singleton_method :params do
            closed_params
          end

          define_singleton_method :default do
            @default ||= new
          end

          define_singleton_method :default= do |client|
            @default = client
          end

          resources.each do |(key, model)|
            define_method key do
              instance_variable_get("@#{key}") ||
                instance_variable_set("@#{key}", 
                  (self.class.const_get("Resource") || WCC::API::RestClient::Resource)
                    .new(self, model, @options)
                )
            end
          end
        end
      end
    end
  end
end