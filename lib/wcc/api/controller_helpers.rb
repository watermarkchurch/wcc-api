module WCC::API
  module ControllerHelpers

    private def set_cache_headers(scope_or_record, options = {})
      options = {public: true, must_revalidate: true}.merge!(options)

      if expiry = options.delete(:expiry)
        expires_in expiry, options.slice(:public, :must_revalidate)
      end

      fresh_when scope_or_record, options.slice(:etag, :public, :last_modified)
    end

  end
end
