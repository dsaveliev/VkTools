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
