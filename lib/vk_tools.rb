require 'rubygems'
require 'mechanize'
require 'patch/mechanize'
require 'ap'
require 'active_support'
require 'active_support/all'

# @author Dmitry Savelev
# Главный модуль, обладающий единственным методом authorize (см. VkTools::Auth)
module VkTools
  extend ActiveSupport::Autoload

  autoload :Base
  autoload :Api
  autoload :Auth
  autoload :Pages

  include Auth
  # Родительский класс - исключение
  class BaseError < Exception; end
  # Класс - исключение, вызывается при проблемах с подключением к серверу
  class ConnectionError < BaseError; end
  # Класс - исключение, вызывается при получении JSON ответа c ошибкой
  class ResponseError < BaseError; end
end
