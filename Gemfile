# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# TODO: temp for now: use `unleash` from the local SDK checkout with `sdk_flavor` config
# Remove this once the Unleash Ruby SDK 6.7+ is published
gem 'unleash', path: '../unleash-ruby-sdk'

group :development, :test do
  gem 'rake', '~> 13.0'
  gem 'rspec', '~> 3.13'
  gem 'rubocop', '~> 1.65'
end
