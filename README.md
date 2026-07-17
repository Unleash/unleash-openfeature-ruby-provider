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

If you cloned without submodules, initialize the verifier harness:

```bash
git submodule update --init --recursive
```

If the verifier submodule is intentionally updated, refresh it and commit the
new submodule pointer:

```bash
git submodule update --remote --merge verifier
git status
```

## Use

```ruby
require 'open_feature/sdk'
require 'unleash-openfeature-provider'

# The provider builds and owns the Unleash client. Pass the same options you
# would give Unleash::Client, it sets its SDK-flavor metadata on top.
provider = Unleash::OpenFeature::Provider::UnleashFlagProvider.new(
  app_name: 'my-ruby-app',
  url: 'https://app.unleash-hosted.com/demo/api',
  custom_http_headers: {
    Authorization: '<client-api-key>'
  }
)

OpenFeature::SDK.configure do |config|
  config.set_provider(provider)
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

The contract tests use the `verifier` submodule. To refresh it:

```bash
git submodule update --remote --merge verifier
```

## Lint

```bash
bundle exec rubocop
```
