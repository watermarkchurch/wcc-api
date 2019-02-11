# frozen_string_literal: true

module WCC::API
  class RestClient
    class ApiError < StandardError
      attr_reader :response

      def self.[](code)
        case code
        when 404
          NotFoundError
        else
          ApiError
        end
      end

      def initialize(response)
        @response = response
        super(response.error_message)
      end
    end

    class NotFoundError < ApiError
    end
  end
end
