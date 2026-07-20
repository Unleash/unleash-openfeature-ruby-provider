# frozen_string_literal: true

require 'logger'
require 'open_feature/sdk/evaluation_context'
require 'unleash/variant'

class FakeClient
  attr_reader :enabled_flags, :variants
  attr_accessor :shutdown_called

  def initialize
    @enabled_flags = {}
    @variants = {}
    @shutdown_called = false
  end

  def is_enabled?(flag_key, _context, default_value)
    enabled_flags.fetch(flag_key, default_value)
  end

  def get_variant(flag_key, _context)
    variants.fetch(flag_key, Unleash::Variant.disabled_variant)
  end

  def shutdown
    self.shutdown_called = true
  end
end

RSpec.describe Unleash::OpenFeature::Provider::UnleashFlagProvider do
  subject(:provider) { described_class.new(logger: Logger.new(nil)) }

  let(:client) { FakeClient.new }

  before do
    allow(Unleash::Client).to receive(:new).and_return(client)
  end

  it 'builds and owns a client with its own sdk flavor stamped on' do
    captured = nil
    allow(Unleash::Client).to receive(:new) do |**opts|
      captured = opts
      client
    end

    provider

    expect(captured[:sdk_flavor]).to eq(Unleash::OpenFeature::Provider::SDK_FLAVOR)
    expect(captured[:sdk_flavor_version]).to eq(Unleash::OpenFeature::Provider::SDK_FLAVOR_VERSION)
  end

  it 'stamps its own sdk flavor even if the caller passes one' do
    captured = nil
    allow(Unleash::Client).to receive(:new) do |**opts|
      captured = opts
      client
    end

    described_class.new(sdk_flavor: 'something-else', logger: Logger.new(nil))

    expect(captured[:sdk_flavor]).to eq(Unleash::OpenFeature::Provider::SDK_FLAVOR)
  end

  it 'resolves boolean flags through the Unleash client' do
    client.enabled_flags['enabled'] = true

    details = provider.fetch_boolean_value(flag_key: 'enabled', default_value: false)

    expect(details.value).to be(true)
    expect(details.reason).to eq(OpenFeature::SDK::Provider::Reason::UNKNOWN)
  end

  it 'resolves string variant payloads' do
    client.variants['string'] = variant('string', 'hello')

    details = provider.fetch_string_value(flag_key: 'string', default_value: 'default')

    expect(details.value).to eq('hello')
    expect(details.variant).to eq('variant-a')
  end

  it 'resolves csv variant payloads as strings' do
    client.variants['csv'] = variant('csv', 'a,b,c')

    details = provider.fetch_string_value(flag_key: 'csv', default_value: 'default')

    expect(details.value).to eq('a,b,c')
  end

  it 'resolves number variant payloads' do
    client.variants['number'] = variant('number', '4.2')

    details = provider.fetch_number_value(flag_key: 'number', default_value: 0)

    expect(details.value).to eq(4.2)
  end

  it 'reports parse errors for empty number payloads' do
    client.variants['number'] = variant('number', '')

    details = provider.fetch_number_value(flag_key: 'number', default_value: 0)

    expect(details.value).to eq(0)
    expect(details.reason).to eq(OpenFeature::SDK::Provider::Reason::ERROR)
    expect(details.error_code).to eq(OpenFeature::SDK::Provider::ErrorCode::PARSE_ERROR)
  end

  it 'resolves json object payloads' do
    client.variants['object'] = variant('json', '{"enabled":true,"count":3}')

    details = provider.fetch_object_value(flag_key: 'object', default_value: {})

    expect(details.value).to eq('enabled' => true, 'count' => 3)
  end

  it 'resolves json array payloads' do
    client.variants['array'] = variant('json', '[1,2,3]')

    details = provider.fetch_object_value(flag_key: 'array', default_value: [])

    expect(details.value).to eq([1, 2, 3])
  end

  it 'returns defaults when variants are disabled' do
    client.variants['disabled'] = variant('string', 'hello', enabled: false)

    details = provider.fetch_string_value(flag_key: 'disabled', default_value: 'default')

    expect(details.value).to eq('default')
    expect(details.reason).to eq(OpenFeature::SDK::Provider::Reason::UNKNOWN)
    expect(details.variant).to eq('variant-a')
  end

  it 'shuts down the Unleash client' do
    provider.shutdown

    expect(client.shutdown_called).to be(true)
  end

  def variant(payload_type, payload_value, enabled: true)
    Unleash::Variant.new(
      name: 'variant-a',
      enabled: enabled,
      payload: {
        'type' => payload_type,
        'value' => payload_value
      }
    )
  end
end
