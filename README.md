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


#### Логирование

Логирование можно подключить следующим образом:

    Vktools.logger = Rails.logger
