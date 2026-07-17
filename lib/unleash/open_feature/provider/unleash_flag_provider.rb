# frozen_string_literal: true

require 'json'
require 'logger'
require 'open_feature/sdk/provider'
require 'unleash'

module Unleash
  module OpenFeature
    module Provider
      class UnleashFlagProvider
        NAME = 'Unleash OpenFeature Provider'

        attr_reader :metadata

        def initialize(**client_options)
          client_options[:sdk_flavor] = SDK_FLAVOR
          client_options[:sdk_flavor_version] = SDK_FLAVOR_VERSION
          logger = client_options[:logger] || Logger.new($stderr)
          setup(::Unleash::Client.new(**client_options), logger)
        end

        # Test-only: wrap a fake client directly, bypasses client construction. Not part of the public API.
        def self.for_client(client, logger: Logger.new($stderr))
          provider = allocate
          provider.send(:setup, client, logger)
          provider
        end

        def init(_evaluation_context = nil)
          # Ruby SDK currently just spins itself up and does the thing
          # Leaving this here because long term plan is to actually have an init method
          # and when that happens this method here needs to get filled in
        end

        def shutdown
          client.shutdown
        end

        def fetch_boolean_value(flag_key:, default_value:, evaluation_context: nil)
          context = Context.to_unleash_context(evaluation_context, logger:)
          value = client.is_enabled?(flag_key, context, default_value)
          resolution(value:, reason: reason::UNKNOWN)
        end

        def fetch_string_value(flag_key:, default_value:, evaluation_context: nil)
          fetch_variant_value(
            flag_key:,
            default_value:,
            evaluation_context:,
            payload_types: %w[string csv], &:to_s
          )
        end

        def fetch_number_value(flag_key:, default_value:, evaluation_context: nil)
          fetch_variant_value(
            flag_key:,
            default_value:,
            evaluation_context:,
            payload_types: %w[number]
          ) { |value| parse_number(value) }
        end

        def fetch_integer_value(flag_key:, default_value:, evaluation_context: nil)
          fetch_variant_value(
            flag_key:,
            default_value:,
            evaluation_context:,
            payload_types: %w[number]
          ) { |value| parse_integer(value) }
        end

        def fetch_float_value(flag_key:, default_value:, evaluation_context: nil)
          fetch_variant_value(
            flag_key:,
            default_value:,
            evaluation_context:,
            payload_types: %w[number]
          ) { |value| parse_float(value) }
        end

        def fetch_object_value(flag_key:, default_value:, evaluation_context: nil)
          fetch_variant_value(
            flag_key:,
            default_value:,
            evaluation_context:,
            payload_types: %w[json],
            parse_error_code: error_code::PARSE_ERROR
          ) { |value| JSON.parse(value) }
        end

        private

        attr_reader :client, :logger

        def setup(client, logger)
          @client = client
          @logger = logger
          @metadata = ::OpenFeature::SDK::Provider::ProviderMetadata.new(name: NAME).freeze
        end

        def fetch_variant_value(flag_key:, default_value:, evaluation_context:, payload_types:,
                                parse_error_code: error_code::PARSE_ERROR)
          context = Context.to_unleash_context(evaluation_context, logger:)
          variant = client.get_variant(flag_key, context)
          payload_value = resolve_payload_value(variant, payload_types)
          value = yield(payload_value)

          resolution(value:, variant: variant.name, reason: reason::UNKNOWN)
        rescue VariantResolutionError => e
          resolution(
            value: default_value,
            variant: e.variant_name,
            reason: e.reason,
            error_code: e.error_code,
            error_message: e.message
          )
        rescue JSON::ParserError, ArgumentError => e
          resolution(
            value: default_value,
            variant: variant&.name,
            reason: reason::ERROR,
            error_code: parse_error_code,
            error_message: e.message
          )
        end

        def resolve_payload_value(variant, payload_types)
          unless variant.enabled
            raise VariantResolutionError.new(
              'Variant is disabled',
              variant_name: variant.name,
              reason: reason::UNKNOWN
            )
          end

          payload = variant.payload || {}
          payload_type = payload_value(payload, 'type')
          payload_value = payload_value(payload, 'value')

          if payload_type.nil?
            raise VariantResolutionError.new(
              'Variant payload type is not present on the resolved variant',
              variant_name: variant.name,
              error_code: error_code::TYPE_MISMATCH
            )
          end

          if payload_value.nil?
            raise VariantResolutionError.new(
              'Variant payload value is not present on the resolved variant',
              variant_name: variant.name,
              error_code: error_code::TYPE_MISMATCH
            )
          end

          return payload_value if payload_types.include?(payload_type)

          raise VariantResolutionError.new(
            "Variant payload has type #{payload_type.inspect}, expected one of #{payload_types.inspect}",
            variant_name: variant.name,
            error_code: error_code::TYPE_MISMATCH
          )
        end

        def payload_value(payload, key)
          payload[key] || payload[key.to_sym]
        end

        def parse_number(value)
          number = parse_float(value)
          return number.to_i if number.to_i == number

          number
        end

        def parse_integer(value)
          Integer(value, 10)
        end

        def parse_float(value)
          Float(value)
        end

        def resolution(value:, reason:, variant: nil, error_code: nil, error_message: nil)
          ::OpenFeature::SDK::Provider::ResolutionDetails.new(
            value:,
            reason:,
            variant:,
            error_code:,
            error_message:
          )
        end

        def reason
          ::OpenFeature::SDK::Provider::Reason
        end

        def error_code
          ::OpenFeature::SDK::Provider::ErrorCode
        end
      end

      class VariantResolutionError < StandardError
        attr_reader :variant_name, :reason, :error_code

        def initialize(message, variant_name:, reason: ::OpenFeature::SDK::Provider::Reason::ERROR, error_code: nil)
          super(message)
          @variant_name = variant_name
          @reason = reason
          @error_code = error_code
        end
      end
    end
  end
end
