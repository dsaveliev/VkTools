require 'spec_helper'

describe VkTools do
  before(:each) do
    FakeWeb.register_uri(
        :any,
        'http://api.vkontakte.ru/oauth/authorize?client_id=2046271&redirect_uri=http%3A%2F%2Fapi.vkontakte.ru%2Fblank.html&display=wap&scope=16383&response_type=code',
        :body => '',
        :status => ["301", "Moved Permanently"],
        :location => 'http://api.vkontakte.ru/blank.html#code=9bf0ba25678eebea9c',
        :set_cookie => ["name=value"]
    )

    FakeWeb.register_uri(
        :any,
        'https://api.vk.com/oauth/token',
        :body => '{"access_token":"8a53a6fa89c9cf5e89c9cf5eac89d6f661089c989c9f0a0f7de91f4e108efc8","expires_in":86400,"user_id":60451236}',
        :status => ["200", "Success"]
    )

    FakeWeb.register_uri(
        :any,
        'https://api.vkontakte.ru/method/getUserInfo?access_token=8a53a6fa89c9cf5e89c9cf5eac89d6f661089c989c9f0a0f7de91f4e108efc8',
        :body => '{"response":{"user_id":"60451236","user_name":null}}',
        :status => ["200", "Success"]
    )

    FakeWeb.register_uri(
        :get,
        'http://m.vkontakte.ru',
        :body => 'В Контакте'
    )

    described_class.client_id = "2046271"
    described_class.client_secret = "N1wu3hhKJ9HGsjuN7pfS"
    described_class.redis_options = {:host => 'localhost', :db => 0} #Пишем в "помойку" - :db => 0, чтобы не запороть случайно данные сервисов


    described_class.send(:redis).flushdb
  end


  context ".authorize" do
    specify "авторизует пользователя на вконтакте по логину/паролю" do
      described_class.authorize('test', 'test', :identity => 79000000000) do |api, pages|
        api.getUserInfo['user_id'].should_not be_nil
        pages.get('http://m.vkontakte.ru').should include('В Контакте')
        api.to_hash[:access_token].should_not be_empty
        pages.to_hash[:cookie].to_s.should_not be_empty
      end
    end

    it "в случае успешной авторизации запоминает данные в redis" do
      described_class.authorize('test', 'test', :identity => 79000000000)

      result = described_class.send(:redis).hgetall("vk_tools_79000000000")
      result.should be_a(Hash)
      result['vk_user_id'].should == "60451236"
      result['access_token'].should == "8a53a6fa89c9cf5e89c9cf5eac89d6f661089c989c9f0a0f7de91f4e108efc8"
    end

    it ".authorize в качестве expires_in устанавливает минимальное значение из ответа вконтакте, и установленного пользователем значения" do
      # Т.к. проверяем прямо в редисе спрашивая ttl, может быть так что тест вдруг залочится на пару секунд, и ttl не будет равен expires_in на это кол-во секунд.
      # Поэтому сделаем порог правильного ответа, равного 3 секунды
      threshold = 3.seconds.to_i

      described_class.authorize('test', 'test', :identity => 79000000000)
      described_class.send(:redis).ttl("vk_tools_79000000000").should be_within(threshold).of(86400)

      described_class.authorize('test', 'test', :identity => 79000000000, :expires_in => 100)
      described_class.send(:redis).ttl("vk_tools_79000000000").should be_within(threshold).of(100)

      described_class.authorize('test', 'test', :identity => 79000000000, :expires_in => 100000)
      described_class.send(:redis).ttl("vk_tools_79000000000").should be_within(threshold).of(86400)
    end
  end


  context "success" do
    it ".api позволяет получить api по запомненной авторизации" do
      described_class.authorize('test', 'test', :identity => 79000000000)
      result = described_class.api(79000000000)
      result.should be_a(VkTools::Api)
      result.to_hash[:access_token].should == "8a53a6fa89c9cf5e89c9cf5eac89d6f661089c989c9f0a0f7de91f4e108efc8"

      described_class.api(79000000001).should be_nil
    end

    it "позволяет получить pages по запомненной авторизации" do
      described_class.authorize('test', 'test', :identity => 79000000000)
      result = described_class.pages(79000000000)
      result.should be_a(VkTools::Pages)
      described_class.pages(79000000001).should be_nil

    end

    specify ".identity_exists?" do
      described_class.authorize('test', 'test', :identity => 79000000000)
      should be_identity_exists(79000000000)
      should_not be_identity_exists(79000000001)
    end

    specify ".forget" do
      described_class.authorize('test', 'test', :identity => 79000000000)
      should be_identity_exists(79000000000)
      described_class.forget(79000000000)
      should_not be_identity_exists(79000000000)
    end

    specify ".access_token_for" do
      described_class.authorize('test', 'test', :identity => 79000000000)
      described_class.access_token_for(79000000000).should == "8a53a6fa89c9cf5e89c9cf5eac89d6f661089c989c9f0a0f7de91f4e108efc8"
    end
  end

  describe "Api error" do
    before(:each) do
      FakeWeb.register_uri(
          :any,
          'http://api.vkontakte.ru/oauth/authorize?client_id=2046271&redirect_uri=http%3A%2F%2Fapi.vkontakte.ru%2Fblank.html&display=wap&scope=16383&response_type=code',
          :body => '',
          :status => ["301", "Moved Permanently"],
          :location => 'http://api.vkontakte.ru/blank.html#code=9bf0ba25678eebea9c',
          :set_cookie => ["name=value"]
      )

      FakeWeb.register_uri(
          :any,
          'https://api.vk.com/oauth/token',
          :body => '{"access_token":"8a53a6fa89c9cf5e89c9cf5eac89d6f661089c989c9f0a0f7de91f4e108efc8","expires_in":0,"user_id":60451236}',
          :status => ["200", "Success"]
      )

      FakeWeb.register_uri(
          :any,
          'https://api.vkontakte.ru/method/getUserInfo?access_token=8a53a6fa89c9cf5e89c9cf5eac89d6f661089c989c9f0a0f7de91f4e108efc8',
          :body => '{"error":{"user_id":"60451236","user_name":null, "error_code" : 1 }}',
          :status => ["200", "Success"]
      )
    end

    it "should process api error" do
      VkTools.client_id = "2046271"
      VkTools.client_secret = "N1wu3hhKJ9HGsjuN7pfS"

      login = "test"
      password = "test"

      lambda {
        api, pages = VkTools.authorize(login, password)
        api.getUserInfo!
      }.should raise_error(VkTools::UnknownError)
    end
  end

  describe "Connection error" do
    before(:each) do
      FakeWeb.register_uri(
          :any,
          'http://api.vkontakte.ru/oauth/authorize?client_id=2046271&redirect_uri=http%3A%2F%2Fapi.vkontakte.ru%2Fblank.html&display=wap&scope=16383&response_type=code',
          :body => '',
          :status => ["301", "Moved Permanently"],
          :location => 'http://api.vkontakte.ru/blank.html#code=9bf0ba25678eebea9c',
          :set_cookie => ["name=value"]
      )

      FakeWeb.register_uri(
          :any,
          'https://api.vk.com/oauth/token',
          :body => '{"access_token":"8a53a6fa89c9cf5e89c9cf5eac89d6f661089c989c9f0a0f7de91f4e108efc8","expires_in":0,"user_id":60451236}',
          :status => ["200", "Success"]
      )

      FakeWeb.register_uri(
          :any,
          'https://api.vkontakte.ru/method/getUserInfo?access_token=8a53a6fa89c9cf5e89c9cf5eac89d6f661089c989c9f0a0f7de91f4e108efc8',
          :body => '',
          :status => ["500", "Internal Server Error"]
      )
    end

    it "should process connection error" do
      VkTools.client_id = "2046271"
      VkTools.client_secret = "N1wu3hhKJ9HGsjuN7pfS"

      login = "test"
      password = "test"

      lambda {
        api, pages = VkTools.authorize(login, password)
        api.getUserInfo!
      }.should raise_error(VkTools::ConnectionError)
    end
  end
end