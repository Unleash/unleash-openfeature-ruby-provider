# frozen_string_literal: true

require 'optparse'
require 'open_feature/sdk'
require 'unleash'
require 'unleash-openfeature-provider'

options = {
  app_name: 'openfeature-ruby-example',
  flag_key: 'my-feature',
  targeting_key: 'user-123'
}

OptionParser.new do |parser|
  parser.banner = 'Usage: ruby examples/boolean_flag.rb --url URL --api-key API_KEY [options]'

  parser.on('--url URL', 'Unleash API URL, for example https://app.unleash-hosted.com/demo/api') do |value|
    options[:url] = value
  end

  parser.on('--api-key API_KEY', 'Unleash client API key') do |value|
    options[:api_key] = value
  end

  parser.on('--flag-key FLAG_KEY', 'Boolean flag key') do |value|
    options[:flag_key] = value
  end

  parser.on('--targeting-key TARGETING_KEY', 'OpenFeature targeting key') do |value|
    options[:targeting_key] = value
  end

  parser.on('--app-name APP_NAME', 'Unleash app name') do |value|
    options[:app_name] = value
  end
end.parse!

missing = %i[url api_key].reject { |key| options[key] }
unless missing.empty?
  warn "Missing required options: #{missing.map { |key| "--#{key.to_s.tr('_', '-')}" }.join(', ')}"
  exit 1
end

unleash_client = Unleash::Client.new(
  app_name: options.fetch(:app_name),
  url: options.fetch(:url),
  custom_http_headers: {
    Authorization: options.fetch(:api_key)
  }
)

OpenFeature::SDK.configure do |config|
  config.set_provider(Unleash::OpenFeature::Provider::UnleashFlagProvider.new(unleash_client))
end

client = OpenFeature::SDK.build_client
context = OpenFeature::SDK::EvaluationContext.new(targeting_key: options.fetch(:targeting_key))

enabled = client.fetch_boolean_value(
  flag_key: options.fetch(:flag_key),
  default_value: false,
  evaluation_context: context
)

puts enabled

unleash_client.shutdown
