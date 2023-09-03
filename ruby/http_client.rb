# frozen_string_literal: true

# Simple HTTP Client
class HTTPClient
  class << self
    def http_get(url, authorization = nil, params = nil)
      uri = URI.parse(url)
      uri.query = URI.encode_www_form(params) unless params.nil?

      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = 'Mozilla/5.0'
      request['Authorization'] = authorization unless authorization.nil?
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
    end
  end
end
