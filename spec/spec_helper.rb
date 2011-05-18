require 'bundler/setup'
require 'vk_tools'
require 'rspec/core'
require 'fakeweb'

RSpec.configure do |config|
  # == Mock Framework
  config.mock_with :rspec

  def stub_any_request
    stub_request(:any, /.*/)
  end

end