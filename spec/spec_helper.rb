require 'bundler/setup'
require 'vk_tools'
require 'rspec/core'
require 'vcr'
require 'lib/vk_tools'

RSpec.configure do |config|
  # == Mock Framework
  config.mock_with :rspec

  VCR.configure do |c|
    c.cassette_library_dir = 'fixtures/vcr_cassettes'
    c.hook_into :webmock
    c.default_cassette_options = { :record => :once }
                                   # не будет работать, куки протухнут.
                                   # :re_record_interval => 7.days }
  end

  def stub_any_request
    stub_request(:any, /.*/)
  end

end
