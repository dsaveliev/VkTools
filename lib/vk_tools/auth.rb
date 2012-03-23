require 'oauth2'
require 'mechanize'

# @author Dmitry Savelev
# Модуль реализует механизм авторизации в vkontakte.ru
module VkTools::Auth

  def self.included(base)
    base.extend(ClassMethods)
  end

  # @author Dmitry Savelev
  # Модуль добавляет в VkTools методы класса
  module ClassMethods
    include VkTools::Base
    # Client ID приложения vkontakte.ru, через которое идут вызовы методов rest api
    attr_accessor :client_id
    # Client Secret приложения vkontakte.ru, через которое идут вызовы методов rest api
    attr_accessor :client_secret
    # Атрибут для подключения логгера
    attr_accessor :logger

    # Опции для подключения к redis.
    # @note Согласно {http://wiki.fun-box.ru/pages/viewpage.action?pageId=10552362 Распределению DB в Redis по сервисам}, VkTools назначен :db => 3
    attr_accessor :redis_options

    # Получить api по запомненной авторизации
    # @param [#to_s] identity Что-то уникально идентифицирующее пользователя между всеми проектами, например msisdn
    # @return [VkTools::Api, nil]
    def api(identity)
      token = access_token_for(identity)
      token && VkTools::Api.new(:access_token => token)
    end

    # Получить pages по запомненной авторизации
    # @param [#to_s] identity Что-то уникально идентифицирующее пользователя между всеми проектами, например msisdn
    # @return [VkTools::Pages, nil]
    def pages(identity)
      cookie = redis.hget(identity_key(identity), 'cookie')
      cookie && VkTools::Pages.new(:cookie => cookie)
    end

    # Авторизация в vkontakte.ru + инициализация VkTools::Api и VkTools::Pages в случае успеха
    # @param [#to_s] login Логин авторизуемого пользователя на ВКонтакте
    # @param [#to_s] password Пароль авторизуемого пользователя на ВКонтакте
    # @param [Hash] options
    # @option options [#to_s] :identity Что-то, однозначно идентифицирующее пользователя консистентно между разными сервисами, например msisdn
    # @option options [#to_s] :expires_in Срок жизни (в секундах) авторизации. Если не установлено - авторизация живет вечно
    # @yieldparam [VkTools::Api] vk_api обертка для доступа к RestApi
    # @yieldparam [VkTools::Pages] vk_pages обертка для доступа к контенту vkontakte.ru
    def authorize(login, password, options = {})
      auth_data = inner_authorize(login, password, options)
      vk_api = VkTools::Api.new :access_token => auth_data[:access_token]
      vk_pages = VkTools::Pages.new :cookie => auth_data[:cookie]
      [vk_api, vk_pages]
    end

    # Авторизация в vkontakte по логину и паролю
    # @param [#to_s] login Логин авторизуемого пользователя на ВКонтакте
    # @param [#to_s] password Пароль авторизуемого пользователя на ВКонтакте
    # @param [Hash] options
    # @option options [#to_s] :identity Что-то, однозначно идентифицирующее пользователя консистентно между разными сервисами, например msisdn
    # @option options [#to_s] :expires_in Срок жизни (в секундах) авторизации. Если не установлено - авторизация живет вечно, но не больше чем срок жизни токена на ВКонтакте
     # @return [Hash] Данные авторизации, в т.ч. :access_token, :cookie, :vk_user_id
    def inner_authorize(login, password, options = {})
      
      @client = OAuth2::Client.new(
        VkTools.client_id,
        VkTools.client_secret,
        :site          => 'https://api.vk.com/',
        :token_url     => '/oauth/token',
        :authorize_url => '/oauth/authorize' 
      )
      auth_url = @client.auth_code.authorize_url(
        :redirect_uri => 'http://api.vk.com/blank.html',
        :scope        => '16383',
        :display      => 'wap'
      )
      agent = Mechanize.new
      auth_data = nil

      begin
        login_page = agent.get(auth_url)
        login_form = login_page.forms.first
        login_form.email = login
        login_form.pass  = password
        
        verify_page = login_form.submit
        
        if verify_page.uri.path == '/oauth/authorize'
          if /m=4/.match(verify_page.uri.query)
            raise VkTools::ResponseError, "Authentification problem"
          elsif /s=1/.match(verify_page.uri.query)
            grant_access_page = verify_page.forms.first.submit
          end
        else
          grant_access_page = verify_page
        end
        
        code = grant_access_page.uri.to_s[/.*code=(.*)&?.*/, 1]
        @access_token = @client.auth_code.get_token(code)
        auth_data = {
          :access_token => @access_token.token,
          :vk_user_id => @access_token.params["user_id"],
          :expires_in => @access_token.expires_in
        }
      rescue Exception => exc
        log_exception(exc)
        return
      end
      
      return unless auth_data
      auth_data.merge!(get_cookies(agent, login, password))
      remember_identity(auth_data, options) if options[:identity].present?
      auth_data
    end

    # Есть ли запомненная авторизация для указанного ident
    # @param [#to_s] ident Что-то, что уникально и переносимо идентифицирует пользователя среди множества проектов (например msisdn)
    def identity_exists?(identity)
      k = identity_key(identity)
      redis.exists(k)
    end

    # Получить запомненный access_token авторизации
    # @param [#to_s] identity Что-то уникально идентифицирующее пользователя между всеми проектами, например msisdn
    # @return [String, nil]
    def access_token_for(identity)
      redis.hget(identity_key(identity), 'access_token')
    end

    # Забыть запомненную авторизацию
    # @param [#to_s] identity Что-то уникально идентифицирующее пользователя между всеми проектами, например msisdn
    # @return [bool] Существовала ли запомненная авторизация до удаления
    def forget(identity)
      res = redis.del(identity_key(identity))
      res > 0
    end

    protected

    def get_cookies(agent, login, password)
      page = agent.get("http://m.vk.com/login")
      form = page.forms.first
      form.email = login
      form.pass = password
      page = agent.submit(form, form.buttons.first)
      cookie_jar = agent.cookie_jar
      cookie = { :cookie => cookie_jar.dump_cookies }
    end

    def redis
      opts = VkTools.redis_options.reverse_merge(:host => '192.168.166.42', :port => 6379, :db => 3)
      require 'redis'
      @redis ||= ::Redis.new(opts)
      @redis
    end

    def identity_key(identity)
      "vk_tools_#{identity}"
    end

    def remember_identity(auth_data, options)
      k = identity_key(options[:identity])
      identity_data = {
          'access_token' => auth_data[:access_token],
          'cookie' => auth_data[:cookie],
          'vk_user_id' => auth_data[:vk_user_id]
      }

      args = identity_data.to_a.flatten

      expires_in = [auth_data[:expires_in], options[:expires_in]].compact.min

      redis.hmset(k, *args)
      redis.expire(k, expires_in.to_i) if expires_in.present? && expires_in.to_i > 0
    end
  end
end
