Классы для взаимодействия с RestApi vkontakte.ru:
====================

Установка
---------

Прописать путь к джему в Gemfile


    gem 'vk_tools', :git => 'git@funbox.beanstalkapp.com:/vk_api.git'


Примеры использования:
----------------------

#### Авторизация

    VkTools.client_id = "1234567"
    VkTools.client_secret = "QWERTYUIOASDFGHJKLS"
    
    VkTools.authorize("login", "password") do |api, pages|
      user_id = api.getUserInfo[:user_id]
      page = pages.get('http://m.vkontakte.ru')
      access_token = api.to_hash[:access_token]
      cookie = pages.to_hash[:cookie]
    end


#### Альтернативный способ

    VkTools.client_id = "1234567"
    VkTools.client_secret = "QWERTYUIOASDFGHJKLS"
    
    api, pages = VkTools.authorize("login", "password")


#### Получение оберток по отдельности

    api = VkTools::Api.new :access_token => some_access_token
    pages = VkTools::Pages.new :cookie => some_cookie

#### Вызовы методов Rest Api
[Документация](http://vkontakte.ru/developers.php?o=-1&p=%CE%EF%E8%F1%E0%ED%E8%E5%20%EC%E5%F2%EE%E4%EE%E2%20API)

    api = VkTools::Api.new :access_token => some_access_token

    user_id = api.getUserInfoEx[:user_id]

    # если в функции присутствует точка - заменяем её на подчеркивание
    messages_count = api.messages_get[0]

    # чтобы НЕ игнорировать исключения, вызываем методы с ! в конце
    # иначе, в случае ошибки, метод вернет nil
    messages_count = api.messages_get![0]


#### Получение страниц vkontakte.ru

    pages = VkTools::Pages.new :cookie => some_cookie

    # URL адрес должен быть полным, т.е. начинаться на http://
    page_1 = pages.get("http://vkontakte.ru")

    # для post запросов нужно передватать хэш параметров
    page_2 = pages.post(some_url, params)

    # предусмотрены аналогичные методы, возвращающие Mechanize::Page
    page_3 = pages.mech_get(some_url)
    page_4 = pages.mech_post(some_url, params)


#### Логирование

Логирование можно подключить следующим образом:

    Vktools.logger = Rails.logger

#### Кросс-проектное запоминание авторизаций пользователей

Запомненные авторизации хранятся в redis. Поэтому необходимо сконфигурировать параметры подключения к нему:

    VkTools.redis_options = {:host => 'localhost', :port => '6379', :db => 3)

Параметры по-умолчанию, которые будут использованы, если не указаны в redis_options:

    self.redis_options.reverse_merge(:host => '192.168.166.42', :port => 6379, :db => 3)

Для того, чтобы запомнить авторизацию пользователя на вконтакте, в методы authorize или inner_authorize
нужно передать опцию :identity - строку или число однозначно и консистетно между проектами идентифицирующих пользователя.


   api, pages = VkTools.authorize('login', 'password', :identity => 123456, :expires_in => 10.days)

или

   auth_data = VkTools.inner_authorize('login', 'password', :identity => 123456, :expires_in => 10.days)


Так же доступны методы получения api и pages по identity:

    api = VkTools.api(123456)                       # Возвращает VkTools::Api или nil
    pages = VkTools.pages(123456)                   # Возвращает VkTools::Pages или nil
    VkTools.identity_exists?(123456)                # Возвращает true/false
    access_token = VkTools.access_token_for(123456) # Возвращает access_token или nil
    VkTools.forget(123456)                          # Забыть данные аутентификации для соотв. пользователя





