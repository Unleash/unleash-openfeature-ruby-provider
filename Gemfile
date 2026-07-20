# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# TEMPORARY (local development): resolve `unleash` from the local SDK checkout,
# which carries the unreleased `sdk_flavor` config option this provider needs.
# Remove once the Unleash Ruby SDK 6.7+ is published to RubyGems.
gem 'unleash', path: '../unleash-ruby-sdk'

group :development, :test do
  gem 'rake', '~> 13.0'
  gem 'rspec', '~> 3.13'
  gem 'rubocop', '~> 1.65'
end
