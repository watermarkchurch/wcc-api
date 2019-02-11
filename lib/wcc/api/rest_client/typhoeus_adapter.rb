# frozen_string_literal: true

require 'forwardable'
gem 'typhoeus'
require 'typhoeus'

module WCC::API
  class RestClient
    class TyphoeusAdapter
      def call(url, query, headers = {}, proxy = {})
        raise NotImplementedError, 'Proxying Not Yet Implemented' if proxy[:host]

        TyphoeusAdapter::Response.new(
          Typhoeus.get(
            url,
            params: query,
            headers: headers
          )
        )
      end

      Response =
        Struct.new(:raw) do
          extend Forwardable

          def_delegators :raw, :body, :to_s, :code, :headers

          def status
            raw.code
          end
        end
    end
  end
end
