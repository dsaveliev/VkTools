require 'rubygems'
require 'mechanize'
require 'patch/mechanize'
require 'ap'
require 'active_support'
require 'active_support/all'

module VkTools
  extend ActiveSupport::Autoload

  autoload :Api
  autoload :Auth
  autoload :Pages

  include Auth
end
