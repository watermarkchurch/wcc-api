module WCC::API
  class RestClient
    class Builder
      def initialize(klass)
        @klass = klass
      end

      def params(*params)
        @params = params.map(&:to_s)
      end

      attr_writer :resource_class
      def resource_class
        @resource_class ||=
          @klass.const_get("Resource") || WCC::API::RestClient::Resource
      end

      def resource(endpoint, model:, **options, &block)
        @resources ||= {}

        resource_class = options[:resource_class] || self.resource_class
        if block_given?
          resource_class = Class.new(resource_class, &block)
        end
        @resources[endpoint] = options.merge({
          resource_class: resource_class,
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
            attr_name = options[:attribute] || endpoint.downcase
            resource_class = options[:resource_class]

            define_method attr_name do
              instance_variable_get("@#{attr_name}") ||
                instance_variable_set("@#{attr_name}", 
                  resource_class.new(self, endpoint, options[:model], @options.merge(options))
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