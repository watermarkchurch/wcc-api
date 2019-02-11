# frozen_string_literal: true

require_relative 'rest_client/response'

module WCC::API
  class RestClient
    attr_reader :api_url

    def initialize(api_url:, headers: nil, **options)
      # normalizes a URL to have a slash on the end
      @api_url = api_url.gsub(/\/+$/, '') + '/'

      @adapter = RestClient.load_adapter(options[:adapter])

      @options = options
      @query_defaults = {}
      @headers = {
        'Accept' => 'application/json',
      }.merge(headers || {}).freeze
      @response_class = options[:response_class] || DefaultResponse
    end

    # performs an HTTP GET request to the specified path within the configured
    # space and environment.  Query parameters are merged with the defaults and
    # appended to the request.
    def get(path, query = {})
      url = URI.join(@api_url, path)

      @response_class.new(self,
        { url: url, query: query },
        get_http(url, query))
    end

    ADAPTERS = {
      http: ['http', '> 1.0', '< 3.0'],
      typhoeus: ['typhoeus', '~> 1.0'],
    }.freeze

    # This method is long due to the case statement,
    # not really a better way to do it
    def self.load_adapter(adapter)
      case adapter
      when nil
        ADAPTERS.each do |a, spec|
          begin
            gem(*spec)
            return load_adapter(a)
          rescue Gem::LoadError
            next
          end
        end
        raise ArgumentError, 'Unable to load adapter!  Please install one of '\
          "#{ADAPTERS.values.map(&:join).join(',')}"
      when :http
        require_relative 'rest_client/http_adapter'
        HttpAdapter.new
      when :typhoeus
        require_relative 'rest_client/typhoeus_adapter'
        TyphoeusAdapter.new
      else
        unless adapter.respond_to?(:call)
          raise ArgumentError, "Adapter #{adapter} is not invokeable!  Please "\
            "pass a proc or use one of #{ADAPTERS.keys}"
        end
        adapter
      end
    end

    private

    def get_http(url, query, headers = {}, proxy = {})
      headers = @headers.merge(headers || {})

      q = @query_defaults.dup
      q = q.merge(query) if query

      resp = @adapter.call(url, q, headers, proxy)

      resp = get_http(resp.headers['location'], nil, headers, proxy) if [301, 302, 307].include?(resp.code) && !@options[:no_follow_redirects]
      resp
    end
  end
end
