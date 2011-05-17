require "rubygems"
require 'net/http'
require 'json'
require 'digest/md5'
require 'mechanize'
require 'monkey_patches/mechanize'
require "ap"

module VkTools
  include Auth
  class << self
    attr_accessor :client_id, :client_secret
    def authorize(login, password)
      auth_data = inner_authorize(login, password)

      vk_api = VkTools::Api.new :access_token => auth_data[:access_token]

      vk_pages = VkTools::Pages.new :cookie => auth_data[:cookie]

      yield vk_api, vk_pages if block_given?
    end
  end
end
