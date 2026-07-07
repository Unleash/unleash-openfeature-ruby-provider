# frozen_string_literal: true

require 'json'
require 'logger'
require 'open_feature/sdk'
require 'unleash'
require 'unleash/bootstrap/configuration'

module ContractVerifierSpec
  ROOT = File.expand_path('..', __dir__)
  CONTRACT_PATH = File.join(ROOT, 'verifier', 'spec', 'contract.json')
  FEATURES_PATH = File.join(ROOT, 'verifier', 'fixtures', 'unleash-features.json')
  CAPABILITIES = %w[localEval perCallContext].freeze
  KNOWN_GAPS = {
    # Left as an example exclusion in case future work requires an exclusion.
    # 'example-scenario-id' => 'Reason this scenario is temporarily excluded'
  }.freeze

  ScenarioResult = Struct.new(:value, :variant, :error_code, keyword_init: true)

  def self.applicable_scenarios
    contract = JSON.parse(File.read(CONTRACT_PATH))
    contract.fetch('scenarios').select do |scenario|
      Array(scenario['requires']).all? { |capability| CAPABILITIES.include?(capability) }
    end
  end
end

RSpec.describe 'OpenFeature verifier contract' do
  before(:all) do
    @register_method = Unleash::Client.instance_method(:register)
    Unleash::Client.define_method(:register) { nil }

    features = File.read(ContractVerifierSpec::FEATURES_PATH)
    bootstrap_config = Unleash::Bootstrap::Configuration.new(data: features)
    unleash_client = Unleash::Client.new(
      app_name: 'openfeature-ruby-verifier',
      url: 'http://unleash-bootstrap.invalid/api',
      custom_http_headers: { Authorization: 'verifier-not-a-real-token' },
      bootstrap_config:,
      disable_metrics: true,
      refresh_interval: 3_600,
      logger: Logger.new(nil)
    )

    @provider = Unleash::OpenFeature::Provider::UnleashFlagProvider.new(unleash_client, logger: Logger.new(nil))
    OpenFeature::SDK.configure do |config|
      config.set_provider_and_wait(@provider)
    end
    @client = OpenFeature::SDK.build_client
  end

  after(:all) do
    @provider.shutdown
    OpenFeature::SDK.configuration.send(:reset)
    Unleash::Client.define_method(:register, @register_method)
  end

  ContractVerifierSpec.applicable_scenarios.each do |scenario|
    it scenario.fetch('id') do
      if ContractVerifierSpec::KNOWN_GAPS.key?(scenario.fetch('id'))
        skip ContractVerifierSpec::KNOWN_GAPS.fetch(scenario.fetch('id'))
      end

      details = evaluate(scenario)
      expected = scenario.fetch('expect')

      expect(details.value).to eq(expected.fetch('value'))
      expect(details.variant).to eq(expected.fetch('variant')) if expected.key?('variant')

      if expected.key?('errorCode')
        expect(details.error_code).to eq(expected.fetch('errorCode'))
      else
        expect(details.error_code).to be_nil
      end
    end
  end

  def evaluate(scenario)
    flag_key = scenario.fetch('flagKey')
    default_value = scenario.fetch('default')
    context = evaluation_context(scenario['context'])

    details = case scenario.fetch('type')
              when 'boolean'
                @client.fetch_boolean_details(flag_key:, default_value:, evaluation_context: context)
              when 'string'
                @client.fetch_string_details(flag_key:, default_value:, evaluation_context: context)
              when 'number'
                @client.fetch_number_details(flag_key:, default_value:, evaluation_context: context)
              when 'object'
                @provider.fetch_object_value(flag_key:, default_value:, evaluation_context: context)
              else
                raise "Unsupported scenario type: #{scenario.fetch('type')}"
              end

    ContractVerifierSpec::ScenarioResult.new(
      value: details.value,
      variant: details.variant,
      error_code: details.error_code
    )
  end

  def evaluation_context(context)
    return nil if context.nil?

    context = context.dup
    targeting_key = context.delete('targetingKey')
    OpenFeature::SDK::EvaluationContext.new(targeting_key:, **context)
  end
end
