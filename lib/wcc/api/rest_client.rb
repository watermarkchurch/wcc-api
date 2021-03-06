# frozen_string_literal: true

require 'wcc'
require_relative 'rest_client/response'
require_relative 'rest_client/builder'
require_relative 'active_record_shim'

module WCC::API
  class RestClient
    attr_reader :api_url

    class << self
      attr_reader :resources, :params

      def rest_client(&block)
        builder = Builder.new(self)
        builder.instance_exec(&block)
        builder.apply
      end
    end

    def initialize(api_url:, headers: nil, **options)
      # normalizes a URL to have a slash on the end
      @api_url = api_url.gsub(/\/+$/, '') + '/'

      @adapter = RestClient.load_adapter(options[:adapter])

      @options = options
      @query_defaults = {}
      @headers = {
        'Accept' => 'application/json'
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

    def post(path, body = {})
      url = URI.join(@api_url, path)

      @response_class.new(self,
        { url: url },
        post_http(url,
          body.to_json,
          headers: { 'Content-Type': 'application/json' }))
    end

    def put(path, body = {})
      url = URI.join(@api_url, path)

      @response_class.new(self,
        { url: url },
        put_http(url,
          body.to_json,
          headers: { 'Content-Type': 'application/json' }))
    end

    def delete(path)
      url = URI.join(@api_url, path)

      @response_class.new(self,
        { url: url },
        delete_http(url))
    end

    ADAPTERS = {
      faraday: ['faraday', '~> 0.9'],
      typhoeus: ['typhoeus', '~> 1.0']
    }.freeze

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
      when :faraday
        require 'faraday'
        ::Faraday.new do |faraday|
          faraday.response :logger, (Rails.logger if defined?(Rails)), { headers: false, bodies: false }
          faraday.adapter :net_http
        end
      when :typhoeus
        require_relative 'rest_client/typhoeus_adapter'
        TyphoeusAdapter.new
      else
        unless adapter.respond_to?(:get)
          raise ArgumentError, "Adapter #{adapter} is not invokeable!  Please "\
            "pass use one of #{ADAPTERS.keys} or create a Faraday-compatible adapter"
        end
        adapter
      end
    end

    private

    def get_http(url, query, headers = {})
      headers = @headers.merge(headers || {})

      q = @query_defaults.dup
      q = q.merge(query) if query

      resp = @adapter.get(url, q, headers)

      resp = get_http(resp.headers['location'], nil, headers) if [301, 302, 307].include?(resp.status) && !@options[:no_follow_redirects]
      resp
    end

    def post_http(url, body, headers: {})
      headers = @headers.merge(headers || {})

      resp = @adapter.post(url, body, headers)

      resp = get_http(resp.headers['location'], nil, headers) if [301, 302, 307].include?(resp.status) && !@options[:no_follow_redirects]
      resp
    end

    def put_http(url, body, headers: {})
      headers = @headers.merge(headers || {})

      resp = @adapter.put(url, body, headers)

      resp = get_http(resp.headers['location'], nil, headers) if [301, 302, 307].include?(resp.status) && !@options[:no_follow_redirects]
      resp
    end

    def delete_http(url, headers: {})
      headers = @headers.merge(headers || {})

      resp = @adapter.delete(url, {}, headers)

      resp = get_http(resp.headers['location'], nil, headers) if [301, 302, 307].include?(resp.status) && !@options[:no_follow_redirects]
      resp
    end

    class Resource
      attr_reader :client, :endpoint, :model, :options

      def initialize(client, endpoint, model, options)
        @client = client
        @endpoint = endpoint
        @model = model
        @options = options
      end

      def find(id, query = {})
        query = (options[:query] || {}).merge(query)
        resp = client.get("#{endpoint}/#{id}", query)
        resp.assert_ok!
        body = options[:key] ? resp.body[options[:key]] : resp.body
        model.new(body, resp.headers.freeze)
      end

      def list(**filters)
        query = extract_params(filters)
        query = (options[:query] || {}).merge(query)
        query = query.merge!(apply_filters(filters, options[:filters]))
        resp = client.get(endpoint, query)
        resp.assert_ok!
        resp.items.map { |s| model.new(s) }
      end

      def create(body)
        resp = client.post(endpoint, body)
        resp.assert_ok!
        maybe_model_from_response(resp)
      end

      def update(id, body)
        resp = client.put("#{endpoint}/#{id}", body)
        resp.assert_ok!
        maybe_model_from_response(resp)
      end

      def destroy(id)
        resp = client.delete("#{endpoint}/#{id}")
        resp.assert_ok!
        maybe_model_from_response(resp)
      end

      protected

      def maybe_model_from_response(resp)
        return true if resp.status == 204
        return true unless resp.raw_body.present?

        body = options[:key] ? resp.body[options[:key]] : resp.body
        return true unless body.present?

        model.new(body, resp.headers.freeze)
      end

      def extract_params(filters)
        filters.each_with_object({}) do |(k, _v), h|
          k_s = k.to_s
          h[k_s] = filters.delete(k) if client.class.params.include?(k_s)
        end
      end

      def filter_key(filter_name)
        filter_name
      end

      def apply_filters(filters, expected_filters)
        defaults = default_filters(expected_filters) || {}
        filters.each_with_object(defaults) do |(k, v), h|
          k = k.to_s
          raise ArgumentError, "Unknown filter '#{k}'" unless expected_filters.include?(k)

          h[filter_key(k)] = v
        end
      end

      def default_filters(expected_filters)
        options[:default_filters]&.each_with_object({}) do |(k, v), h|
          k = k.to_s
          h[filter_key(k)] = v if expected_filters.include?(k)
        end
      end
    end
  end
end
