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
    def get_user(id, include_models = [])
      params = {}
      include_models = include_models.select { |x| x.in? %w[contact_methods notification_rules teams subdomains] }
      params.merge({ include: include_models }) if include_models.any?
      http_get("users/#{id}", params)
    end

    def get_users(limit = 25, offset = 0, include_models = [], query = nil, team_ids = [], total: false)
      params = { limit: limit, offset: offset, total: total }
      include_models = include_models.select { |x| x.in? %w[contact_methods notification_rules teams subdomains] }
      params.merge({ include: include_models }) if include_models.any?
      params.merge({ query: query }) unless query.nil?
      params.merge({ team_ids: team_ids }) if team_ids.any?
      http_get('users', params)
    end

    def all_users(batch_size = 25, *args, **kwargs)
      get_until_exhaustion(:get_users, 'users', batch_size, *args, **kwargs)
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

    def all_escalation_policies(batch_size = 25, *args, **kwargs)
      get_until_exhaustion(:get_escalation_policies, 'escalation_policies', batch_size, *args, **kwargs)
    end

    def get_extension_schemas(limit = 100, offset = 0, total: false)
      params = { limit: limit, offset: offset, total: total }
      http_get('extension_schemas', params)
    end

    def all_extension_schemas(batch_size = 25, *args, **kwargs)
      get_until_exhaustion(:get_extension_schemas, 'extension_schemas', batch_size, *args, **kwargs)
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def get_incidents(limit = 100, offset = 0, date_range = nil, include_models = [], service_ids = [],
                      since_date = nil, sort_by = [], statuses = [], time_zone = 'America/Santiago', until_date = nil,
                      urgencies = [], user_ids = [], total: false)
      params = { limit: limit, offset: offset, total: total, time_zone: time_zone }
      if date_range.eql?('all')
        params.merge({ date_range: date_range })
      else
        params.merge({ since: since_date }) unless since_date.nil?
        params.merge({ until: until_date }) unless until_date.nil?
      end
      include_models = include_models.select do |x|
        x.in? %w[acknowledgers agents assignees conference_bridge escalation_policies first_trigger_log_entries
                 priorities services teams users]
      end
      params.merge({ include: include_models }) if include_models.any?
      params.merge({ service_ids: service_ids }) if service_ids.any?
      params.merge({ sort_by: sort_by.slice(0, 1) }) if sort_by.any?
      statuses = statuses.select { |x| x.in? %w[triggered acknowledged resolved] }
      params.merge({ statuses: statuses }) if statuses.any?
      urgencies = urgencies.select { |x| x.in? %w[high low] }
      params.merge({ urgencies: urgencies }) if urgencies.any?
      params.merge({ user_ids: user_ids }) if user_ids.any?
      http_get('incidents', params)
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def all_incidents(batch_size = 25, *args, **kwargs)
      get_until_exhaustion(:get_incidents, 'incidents', batch_size, *args, **kwargs)
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

    def log(info)
      puts info if DEBUG
    end

    def get_until_exhaustion(func, items_key, batch_size = 25, *args, **kwargs)
      more = true
      offset = 0
      items = []

      while more
        response = method(func).call(batch_size, offset, *args, **kwargs)
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

single_user = PagerdutyClient.get_user('PLOASXQ')
single_user = JSON.parse(single_user.body)
puts(single_user.dig('user', 'name'))

# ESCALATION POLICIES
eps = PagerdutyClient.all_escalation_policies
puts eps.size
puts(eps.map { |u| u['name'] })

# EXTENSION SCHEMAS
ess = PagerdutyClient.all_extension_schemas
puts ess.size
puts(ess.map { |u| u['label'] })

# INCIDENTS
incidents = PagerdutyClient.all_incidents
puts incidents.size
puts(incidents.map { |i| i['title'] })
