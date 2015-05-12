module WCC::API
  class BaseQuery
    attr_reader :scope, :paging
    attr_accessor :limit, :offset
    attr_accessor :filter

    MAX_LIMIT = 50

    def default
      {
        limit: 20,
        offset: 0,
        filter: {}
      }
    end

    def permitted_keys
      %i(limit offset filter)
    end

    def default_scope
      raise NotImplementedError
    end

    def initialize(params, scope: default_scope, paging: true)
      @scope = scope
      @paging = paging
      set_defaults
      permitted_keys.each do |key|
        self.public_send("#{key}=", params[key]) if params.has_key?(key)
      end
    end

    def call(scope=self.scope)
      scope = scope.dup
      scope = paged(scope)
      scope = ordered(scope)
      scope = filtered(scope)
      scope
    end

    def paged(scope=self.scope)
      if paging
        scope
          .limit(limit)
          .offset(offset)
      else
        scope
      end
    end

    def ordered(scope=self.scope)
      scope
    end

    def filtered(scope=self.scope)
      scope
    end

    def set_defaults
      default.each do |key, value|
        public_send("#{key}=", value)
      end
    end

    def limit=(new_limit)
      new_limit = new_limit.to_i
      @limit = (new_limit > MAX_LIMIT) ? MAX_LIMIT : new_limit
    end

    def offset=(new_offset)
      @offset = new_offset.to_i
    end

    def total
      @total ||= filtered.count
    end

    def size
      if total - offset < limit
        total - offset
      else
        limit
      end
    end
  end
end

