# frozen_string_literal: true

require 'logger'
require 'unleash/context'

module Unleash
  module OpenFeature
    module Provider
      module Context
        BASE_CONTEXT_KEYS = {
          'currentTime' => 'currentTime',
          'userId' => 'userId',
          'sessionId' => 'sessionId',
          'remoteAddress' => 'remoteAddress',
          'environment' => 'environment',
          'appName' => 'appName'
        }.freeze

        module_function

        def to_unleash_context(evaluation_context, logger: Logger.new($stderr))
          return Unleash::Context.new if evaluation_context.nil?

          context = {}
          properties = {}

          evaluation_context.fields.each do |key, value|
            next if key == 'targeting_key'

            if BASE_CONTEXT_KEYS.key?(key)
              context[BASE_CONTEXT_KEYS.fetch(key)] = value
            elsif scalar?(value)
              properties[key] = value
            else
              logger.debug("Discarding nested Unleash context property: #{key}")
            end
          end

          context['userId'] = evaluation_context.targeting_key unless evaluation_context.targeting_key.nil?
          context['properties'] = properties unless properties.empty?

          Unleash::Context.new(context)
        end

        def scalar?(value)
          value.nil? || value.is_a?(String) || value.is_a?(Numeric) ||
            value == true || value == false || value.is_a?(Time)
        end
      end
    end
  end
end
