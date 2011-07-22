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
  class Error < ::Exception; end
  # Класс - исключение, вызывается при проблемах с подключением к серверу
  class ConnectionError < Error; end
  # Класс - исключение, вызывается при получении JSON ответа c ошибкой
  class ResponseError < Error
    attr_accessor :vk_error_code
    attr_accessor :request_params
    attr_accessor :payload
  end

  class CaptchaNeeded < ResponseError; end
  class UnknownError < ResponseError; end
  class ApplicationDisabled < ResponseError; end
  class IncorrectSignature < ResponseError; end
  class UserAuthFailed < ResponseError; end
  class TooManyRequestsPerSecond < ResponseError; end
  class PermissionDenied < ResponseError; end
  class ParameterMissingOrInvalid < ResponseError; end
end
