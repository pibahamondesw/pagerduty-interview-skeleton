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
    def get_users(limit, offset, include_models = [], query = nil, team_ids = [], total: false)
      params = { limit: limit, offset: offset, total: total }
      include_models = include_models.select { |x| x.in? %w[contact_methods notification_rules teams subdomains] }
      params.merge({ include: include_models }) if include_models.any?
      params.merge({ query: query }) unless query.nil?
      params.merge({ team_ids: team_ids }) if team_ids.any?
      http_get('users', params)
    end

    def all_users(batch_size = 25)
      get_until_exhaustion(:get_users, 'users', batch_size)
    end

    def get_escalation_policies(limit = 100, offset = 0, include_models = [], query = nil, sort_by = nil,
                                team_ids = [], user_ids = [], total: false)
      params = { limit: limit, offset: offset, total: total }
      include_models = include_models.select { |x| x.in? %w[services teams targets] }
      params.merge({ include: include_models }) if include_models.any?
      params.merge({ query: query }) unless query.nil?
      params.merge({ sort_by: sort_by }) unless sort_by.nil?
      params.merge({ team_ids: team_ids }) if team_ids.any?
      params.merge({ user_ids: user_ids }) if user_ids.any?
      http_get('escalation_policies', params)
    end

    def all_escalation_policies(batch_size = 25)
      get_until_exhaustion(:get_escalation_policies, 'escalation_policies', batch_size)
    end

    private

    def http_get(endpoint, params = nil)
      url = "#{BASE_URL}/#{endpoint}"
      authorization = "Token token=#{PD_TOKEN}"
      log "Sending 'GET' request to URL : #{url}"
      response = HTTPClient.http_get(url, authorization, params)
      log "Response Code : #{response.code}"
      log JSON.pretty_generate(JSON.parse(response.body))
      response
    end

    def input_line
      $stdin.gets.chomp
    end

    def log(info)
      puts info if DEBUG
    end

    def get_until_exhaustion(func, items_key, batch_size = 25)
      more = true
      offset = 0
      items = []

      while more
        response = method(func).call(batch_size, offset)
        items_batch = JSON.parse(response.body)
        items += items_batch[items_key]
        more = items_batch['more']
        offset += batch_size
      end

      items
    end
  end
end

# Usage examples

# USERS
users = PagerdutyClient.all_users
puts users.size
puts(users.map { |u| u['name'] })

# ESCALATION POLICIES
eps = PagerdutyClient.all_escalation_policies
puts eps.size
puts(eps.map { |u| u['name'] })
