# frozen_string_literal: true

require 'logger'
require 'open_feature/sdk/evaluation_context'

RSpec.describe Unleash::OpenFeature::Provider::Context do
  describe '.to_unleash_context' do
    it 'maps base fields and moves custom fields into properties' do
      evaluation_context = OpenFeature::SDK::EvaluationContext.new(
        targeting_key: 'targeting-user',
        'userId' => 'explicit-user',
        'sessionId' => 'session-123',
        'thing' => 'test',
        'enabled' => true,
        'count' => 3
      )

      context = described_class.to_unleash_context(evaluation_context, logger: Logger.new(nil))

      expect(context.user_id).to eq('targeting-user')
      expect(context.session_id).to eq('session-123')
      expect(context.properties).to include(thing: 'test', enabled: true, count: 3)
    end

    it 'discards nested custom fields' do
      evaluation_context = OpenFeature::SDK::EvaluationContext.new('nested' => { 'thing' => 'test' })

      context = described_class.to_unleash_context(evaluation_context, logger: Logger.new(nil))

      expect(context.properties).to be_empty
    end
  end
end
