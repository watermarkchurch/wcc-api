module WCC::API::ActiveRecordShim
  def self.included(base)
    base.public_send :include, InstanceMethods
    base.extend ClassMethods
  end

  module InstanceMethods
    def attributes
      raw.keys.each_with_object({}) do |key, h|
        next unless respond_to?(key)

        val = public_send(key)
        h[key] =
          if val.is_a? Array
            val.map { |v| v.respond_to?(:to_h) ? v.to_h : v }
          else
            val.respond_to?(:to_h) ? val.to_h : val
          end
      end
    end
  end

  module ClassMethods
    def find(id)
      client.public_send(endpoint).find(id)
    end

    def find_all(**filters)
      client.public_send(endpoint).list(filters)
    end

    def find_by(**filters)
      raise ArgumentError, "You must provide at least one filter" if filters.empty?

      find_all(filters).first
    end

    def model_name
      name
    end

    def table_name
      endpoint
    end

    def unscoped
      yield
    end

    def find_in_batches(options, &block)
      options = options ? options.dup : {}
      batch_size = options.delete(:batch_size) || 1000
      skip_param = [:skip, :offset]

      filter = {
        limit: batch_size,
        offset: options.delete(:start) || 0
      }

      find_all(filter).each_slice(batch_size, &block)
    end

    def where(**conditions)
      # TODO: return a Query object that implements more of the ActiveRecord query interface
      # https://guides.rubyonrails.org/active_record_querying.html#conditions
      find_all(conditions)
    end
  end
end