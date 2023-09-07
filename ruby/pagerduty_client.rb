# frozen_string_literal: true

require 'json'
require 'net/http'
require_relative 'http_client'
require_relative 'helpers'

# PagerDuty Client skeleton for interview
class PagerdutyClient
  BASE_URL = 'https://api.pagerduty.com'
  DEBUG = ENV.fetch('DEBUG', nil) == 'true'
  PD_TOKEN = ENV.fetch('PD_TOKEN', 'y_NbAkKc66ryYTWUXYEu')

  class << self
    def get_user(id, include_models = [])
      params = {}
      include_models = include_models.select { |x| %w[contact_methods notification_rules teams subdomains].include?(x) }
      params.merge!({ 'include[]' => include_models }) if include_models.any?
      http_get("users/#{id}", params)
    end

    def get_users(limit = 25, offset = 0, include_models = [], query = nil, team_ids = [], total: false)
      params = { limit: limit, offset: offset, total: total }
      if include_models.any?
        include_models = include_models.select do |x|
          %w[contact_methods notification_rules teams subdomains].include?(x)
        end
        params.merge!({ 'include[]' => include_models })
      end
      params.merge!({ query: query }) unless query.nil?
      params.merge!({ team_ids: team_ids }) if team_ids.any?
      http_get('users', params)
    end

    def all_users(batch_size = 25, *args, **kwargs)
      get_until_exhaustion(:get_users, 'users', batch_size, *args, **kwargs)
    end

    def get_escalation_policies(limit = 100, offset = 0, include_models = [], query = nil, sort_by = nil,
                                team_ids = [], user_ids = [], total: false)
      params = { limit: limit, offset: offset, total: total }
      include_models = include_models.select { |x| %w[services teams targets].include?(x) }
      params.merge!({ 'include[]' => include_models }) if include_models.any?
      params.merge!({ query: query }) unless query.nil?
      params.merge!({ sort_by: sort_by }) unless sort_by.nil?
      params.merge!({ team_ids: team_ids }) if team_ids.any?
      params.merge!({ user_ids: user_ids }) if user_ids.any?
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
        params.merge!({ date_range: date_range })
      else
        params.merge!({ since: since_date }) unless since_date.nil?
        params.merge!({ until: until_date }) unless until_date.nil?
      end
      include_models = include_models.select do |x|
        %w[acknowledgers agents assignees conference_bridge escalation_policies first_trigger_log_entries
           priorities services teams users].include?(x)
      end
      params.merge!({ 'include[]' => include_models }) if include_models.any?
      params.merge!({ service_ids: service_ids }) if service_ids.any?
      params.merge!({ sort_by: sort_by.slice(0, 1) }) if sort_by.any?
      statuses = statuses.select { |x| %w[triggered acknowledged resolved].include?(x) }
      params.merge!({ statuses: statuses }) if statuses.any?
      urgencies = urgencies.select { |x| %w[high low].include?(x) }
      params.merge!({ urgencies: urgencies }) if urgencies.any?
      params.merge!({ user_ids: user_ids }) if user_ids.any?
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

offset = 0
limit = 10

loop do
  users = PagerdutyClient.get_users(limit, offset, total: true)
  users = JSON.parse(users.body)
  total_users = users['total']
  fetched_users = users['users'].size
  puts "Showing #{fetched_users} users out of #{total_users}"

  idx = 0

  users['users'].each do |user|
    puts "#{idx}: #{user['name']}"
    idx += 1
  end

  puts "\nSelect an option:"
  puts "P: Show previous #{limit}" if offset.positive?
  puts "N: Show next #{limit}" if offset + fetched_users < total_users
  puts "0-#{fetched_users}: Select user"
  puts 'X: Close'

  input_text = input_line

  if input_text.eql?('N')
    offset += limit
    next
  elsif input_text.eql?('P')
    offset -= limit
    next
  elsif valid_number?(input_text, limit)
    n = Integer(input_text)
    user_id = users['users'][n]['id']
    user = PagerdutyClient.get_user(user_id, ['contact_methods'])
    user = JSON.parse(user.body)['user']
    puts "#{user['name']}\n"
    user['contact_methods'].each do |contact_method|
      case contact_method['type']
      when 'email_contact_method'
        puts "Email (#{contact_method['label']})"
      when 'sms_contact_method'
        puts "SMS (#{contact_method['label']})"
      when 'phone_contact_method'
        puts "Phone number (#{contact_method['label']})"
      end
      puts "#{contact_method['address']}\n"
    end
    puts "\nPress enter to go back"
    input_line
  elsif input_text.eql?('X')
    break
  end
end
