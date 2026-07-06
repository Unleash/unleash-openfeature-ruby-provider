# Unleash OpenFeature Ruby Provider

The official Unleash OpenFeature provider for Ruby.

## Requirements

- Ruby 3.4+
- Bundler

## Install

```ruby
gem 'unleash-openfeature-provider'
```

For local development:

```bash
bundle install
```

## Use

```ruby
require 'open_feature/sdk'
require 'unleash'
require 'unleash-openfeature-provider'

unleash_client = Unleash::Client.new(
  app_name: 'my-ruby-app',
  url: 'https://app.unleash-hosted.com/demo/api',
  custom_http_headers: {
    Authorization: '<client-api-key>'
  }
)

OpenFeature::SDK.configure do |config|
  config.set_provider(Unleash::OpenFeature::Provider::UnleashFlagProvider.new(unleash_client))
end

client = OpenFeature::SDK.build_client
enabled = client.fetch_boolean_value(
  flag_key: 'my-feature',
  default_value: false,
  evaluation_context: OpenFeature::SDK::EvaluationContext.new(targeting_key: 'user-123')
)
```

## Example

```bash
bundle exec ruby examples/boolean_flag.rb \
  --url https://app.unleash-hosted.com/demo/api \
  --api-key "$UNLEASH_API_KEY" \
  --flag-key my-feature \
  --targeting-key user-123
```

## Build

```bash
bundle exec rake build
```

Build artifacts are written to `pkg/`.

## Test

```bash
bundle exec rspec
```

## Lint

```bash
bundle exec rubocop
```
