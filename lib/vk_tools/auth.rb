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
      #TODO: А давайте уберем остюда yield'ы. Помоему они тут совершенно не уместны, т.к. после yield никакой деструкции не делается,результат открутки блока ни на что не влияет, повышения удобства синтаксиса не несет
      auth_data = inner_authorize(login, password, options)
      vk_api = VkTools::Api.new :access_token => auth_data[:access_token]
      vk_pages = VkTools::Pages.new :cookie => auth_data[:cookie]
      if block_given?
        yield vk_api, vk_pages 
      else
        [vk_api, vk_pages]
      end
    end


    # Авторизация в vkontakte по логину и паролю
    # @param [#to_s] login Логин авторизуемого пользователя на ВКонтакте
    # @param [#to_s] password Пароль авторизуемого пользователя на ВКонтакте
    # @param [Hash] options
    # @option options [#to_s] :identity Что-то, однозначно идентифицирующее пользователя консистентно между разными сервисами, например msisdn
    # @option options [#to_s] :expires_in Срок жизни (в секундах) авторизации. Если не установлено - авторизация живет вечно, но не больше чем срок жизни токена на ВКонтакте
     # @return [Hash] Данные авторизации, в т.ч. :access_token, :cookie, :vk_user_id
    def inner_authorize(login, password, options = {})
      redirect_uri = CGI.escape("http://api.vkontakte.ru/blank.html")

      path = "http://api.vkontakte.ru/oauth/authorize?client_id=#{VkTools.client_id}&redirect_uri=#{redirect_uri}&display=wap&scope=16383&response_type=code"
      agent = Mechanize.new
      page = agent.get(path)
      form = page.forms.first
      if !!form
        form.email = login
        form.pass = password
        page = agent.submit(form, form.buttons.first)
      end
      unless page.uri.to_s.include?('code=')
        form = page.forms.first
        page = agent.submit(form, form.buttons.first)
      end
      cookie_jar = agent.cookie_jar
      cookie = { :cookie => cookie_jar.dump_cookies }
      code = page.uri.to_s[/code=(.*)/, 1]
      auth_data = get_access_token(code)
      return unless auth_data

      auth_data.merge!(cookie)

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

    def get_access_token(code)
      return unless code && !code.empty?
      http = Net::HTTP.new('api.vk.com', 443)
      http.use_ssl = true
      path = '/oauth/token'
      data = "client_id=#{VkTools.client_id}&\
              client_secret=#{VkTools.client_secret}&\
              code=#{code}"
      headers = {'Content-Type' => 'application/x-www-form-urlencoded'}

      begin
        resp, data = http.post(path, data, headers)
        unless resp.code_type == Net::HTTPOK
          raise VkTools::ConnectionError, "Bad response from api.vk.com: #{resp.code}"
        end
        attributes = JSON.parse(data)

        if attributes.has_key?("error")
          raise VkTools::ResponseError, "Authentification problem: #{attributes['error']}"
        end
        {
          :access_token => attributes['access_token'],
          :vk_user_id => attributes['user_id'],
          :expires_in => attributes['expires_in']
        }
      rescue Exception => exc
        log_exception(exc)
        return
      end
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
