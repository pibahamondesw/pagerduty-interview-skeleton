# frozen_string_literal: true

require 'json'
require 'net/http'
require_relative 'http_client'

# PagerDuty Client skeleton for interview
class PagerdutyClient
  BASE_URL = 'https://api.pagerduty.com'
  DEBUG = ENV.fetch('DEBUG', nil) == 'true'
  PD_TOKEN = ENV.fetch('PD_TOKEN', 'y_NbAkKc66ryYTWUXYEu')

  class << self
    def get_users(limit, offset, include_models = [], query = nil, team_ids = [], retries = 3, total: false)
      params = { limit: limit, offset: offset, total: total }
      include_models = include_models.select { |x| x.in? %w[contact_methods notification_rules teams subdomains] }
      params.merge({ include: include_models }) if include_models.any?
      params.merge({ query: query }) unless query.nil?
      params.merge({ team_ids: team_ids }) if team_ids.any?
      response = http_get('users', params)

      return response if response['status'] != 200

      return get_users(limit, offset, include_models, query, team_ids, retries - 1) if retries.positive?

      raise 'Error while trying to get users'
    end

    def all_users(batch_size = 25)
      more = true
      offset = 0
      users = []

      while more
        response = get_users(batch_size, offset)
        parsed_body = json_to_map(response.body)
        users += parsed_body['users']
        more = parsed_body['more']
        offset += batch_size
      end
      users
    end

    private

    def http_get(endpoint, params = nil)
      url = "#{BASE_URL}/#{endpoint}"
      authorization = "Token token=#{PD_TOKEN}"
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

    def log(info)
      puts info if DEBUG
    end
  end
end

# Usage examples

# USERS
users = PagerdutyClient.all_users
puts users.size
puts(users.map { |u| u['name'] })
