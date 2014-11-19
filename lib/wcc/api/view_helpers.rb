module WCC::API
  module ViewHelpers

    def api_pagination_for(query:)
      WCC::API::JSON::Pagination.new(
        query,
        url_for: -> (params) { url_for(params) }
      ).to_builder
    end

  end
end
