# frozen_string_literal: true

require 'bundler/setup'
require 'unleash/open_feature/provider'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }
end
