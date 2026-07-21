# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# TEMPORARY: the `sdk_flavor` config this provider needs isn't on RubyGems yet.
# Remove this once the Unleash Ruby SDK 6.7+ is published
# and in CI (no sibling checkout required). Remove once Unleash Ruby SDK 6.7 ships.
gem 'unleash', git: 'https://github.com/Unleash/unleash-ruby-sdk', branch: 'feat/sdk-flavor-metadata'

group :development, :test do
  gem 'rake', '~> 13.0'
  gem 'rspec', '~> 3.13'
  gem 'rubocop', '~> 1.65'
end
