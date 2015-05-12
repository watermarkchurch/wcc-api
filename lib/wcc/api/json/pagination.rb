module WCC::API::JSON
  class Pagination
    attr_reader :query, :url_for

    def initialize(query, url_for:)
      @query = query
      @url_for = url_for
    end

    def to_builder
      Jbuilder.new do |json|
        json.total query.total
        if query.paging
          json.size query.size
          json.limit query.limit
          json.offset query.offset
        end
        json.order_by query.order_by if query.respond_to?(:order_by)
        json.sort query.sort if query.respond_to?(:sort)
        json.filter query.filter
        json._links do
          json.self url_for.(base_url_params)
          if has_previous_page?
            json.previous url_for.(base_url_params.merge(offset: query.offset - query.limit))
          end
          if has_next_page?
            json.next url_for.(base_url_params.merge(offset: query.offset + query.limit))
          end
        end
      end
    end

    private

    def has_previous_page?
      query.offset - query.limit >= 0
    end

    def has_next_page?
      query.offset + query.limit < query.total
    end

    def base_url_params
      @base_url_params ||= {
        limit: query.limit,
        offset: query.offset,
        filter: query.filter,
        only_path: false
      }.tap do |params|
        params[:order_by] = query.order_by if query.respond_to?(:order_by)
        params[:sort] = query.sort if query.respond_to?(:sort)
      end
    end
  end
end
