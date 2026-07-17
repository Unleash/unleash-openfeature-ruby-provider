# frozen_string_literal: true

require_relative 'lib/unleash/open_feature/provider/version'

Gem::Specification.new do |spec|
  spec.name = 'unleash-openfeature-provider'
  spec.version = Unleash::OpenFeature::Provider::VERSION
  spec.authors = ['Unleash']
  spec.email = ['opensource@getunleash.io']

  spec.summary = 'The official Unleash OpenFeature provider for Ruby.'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/Unleash/unleash-openfeature-ruby-provider'
  spec.license = 'Apache-2.0'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.glob('lib/**/*.rb') + ['LICENSE', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'openfeature-sdk', '0.6.0'
  # Needs the release that adds the `sdk_flavor` / `sdk_flavor_version`
  spec.add_dependency 'unleash', '~> 6.7'
end
