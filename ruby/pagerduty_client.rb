# frozen_string_literal: true

require 'json'
require 'net/http'
require_relative 'http_client'

# PagerDuty Client skeleton for interview
class PagerdutyClient
  BASE_URL = 'https://api.pagerduty.com'
  DEBUG = ENV.fetch('DEBUG', nil) == 'true'

  def initialize
    set_token
  end

  def http_get(endpoint, params = nil)
    url = "#{BASE_URL}/#{endpoint}"
    authorization = "Token token=#{@pd_token}"
    log "Sending 'GET' request to URL : #{url}"
    response = HTTPClient.http_get(url, authorization, params)
    log "Response Code : #{response.code}"
    log JSON.pretty_generate(json_to_map(response.body))
    response
  end

  def json_to_map(json_string)
    JSON.parse(json_string)
  end

  def input_line
    $stdin.gets.chomp
  end

  private

  def set_token
    @pd_token = ENV.fetch('PD_TOKEN', nil)
    raise 'You need to set the environment variable "PD_TOKEN" to use this Client' if @pd_token.nil?
  end

  def log(info)
    puts info if DEBUG
  end
end
