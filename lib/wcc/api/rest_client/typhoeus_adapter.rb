# frozen_string_literal: true

require 'forwardable'
gem 'typhoeus'
require 'typhoeus'

class WCC::API::RestClient::TyphoeusAdapter
  def get(url, params = {}, headers = {})
    req = OpenStruct.new(params: params, headers: headers)
    yield req if block_given?
    Response.new(
      Typhoeus.get(
        url,
        params: req.params,
        headers: req.headers
      )
    )
  end

  def post(url, body, headers = {}, proxy = {})
    raise NotImplementedError, 'Proxying Not Yet Implemented' if proxy[:host]

    Response.new(
      Typhoeus.post(
        url,
        body: body.to_json,
        headers: headers
      )
    )
  end

  class Response < SimpleDelegator
    def raw
      __getobj__
    end

    def to_s
      body&.to_s
    end

    def status
      code
    end
  end
end

