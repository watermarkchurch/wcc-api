# frozen_string_literal: true

require 'forwardable'
require_relative 'api_error'

module WCC::API
  class RestClient
    class AbstractResponse
      extend ::Forwardable

      attr_reader :raw_response
      attr_reader :raw_body
      attr_reader :client
      attr_reader :request

      def_delegators :raw_response, :code, :headers

      def body
        @body ||= ::JSON.parse(raw_body)
      end
      alias_method :to_json, :body

      def initialize(client, request, raw_response)
        @client = client
        @request = request
        @raw_response = raw_response
        @raw_body = raw_response.body.to_s
      end

      def skip
        throw new NotImplementedError, 'Please implement "skip" parsing in response class'
      end

      def count
        throw new NotImplementedError, 'Please implement "count" parsing in response class'
      end

      def collection_response?
        page_items.nil? ? false : true
      end

      def page_items
        throw new NotImplementedError, 'Please implement "page_items" parsing in response class'
      end

      def error_message
        parsed_message =
          begin
            body.dig('error', 'message') || body.dig('message')
          rescue ::JSON::ParserError
            nil
          end
        parsed_message || "#{code}: #{raw_response.body}"
      end

      def next_page?
        return false unless collection_response?
        return false if count.nil?

        page_items.length + skip < count
      end

      def next_page
        return unless next_page?

        @next_page ||= @client.get(
          @request[:url],
          (@request[:query] || {}).merge(next_page_query)
        )
        @next_page.assert_ok!
      end

      def assert_ok!
        return self if code >= 200 && code < 300

        raise ApiError[code], self
      end

      # This method has a bit of complexity that is better kept in one location
      def each_page(&block)
        raise ArgumentError, 'Not a collection response' unless collection_response?

        ret =
          Enumerator.new do |y|
            y << self

            if next_page?
              next_page.each_page.each do |page|
                y << page
              end
            end
          end

        if block_given?
          ret.map(&block)
        else
          ret.lazy
        end
      end

      def items
        return unless collection_response?

        each_page.flat_map(&:page_items)
      end

      def first
        raise ArgumentError, 'Not a collection response' unless collection_response?

        page_items.first
      end

      def next_page_query
        return unless collection_response?

        {
          skip: page_items.length + skip
        }
      end
    end

    class DefaultResponse < AbstractResponse
      def skip
        body['skip']
      end

      def count
        body['total']
      end

      def page_items
        body['items']
      end
    end
  end
end
