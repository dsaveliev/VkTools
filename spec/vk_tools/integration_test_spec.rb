require 'spec_helper'

describe VkTools do
  before(:each) do
    described_class.client_id = "2046271"
    described_class.client_secret = "N1wu3hhKJ9HGsjuN7pfS"
    described_class.redis_options = {:host => 'localhost', :db => 0} #Пишем в "помойку" - :db => 0, чтобы не запороть случайно данные сервисов
    described_class.send(:redis).flushdb

    @token = "fdecbb0bfe76d2affe76d2afb8fe69eb90ffe76fe76ed50f838aad6eacb69b2"
    @cookie = "login.vk.com\tFALSE\t/\tFALSE\t1359221530\tl\t60451236\nlogin.vk.com\tFALSE\t/\tFALSE\t1360038869\tp\t85951f06bf294db366a916ef35f996678c24\nlogin.vk.com\tFALSE\t/\tFALSE\t1359453517\ts\t1\nvk.com\tFALSE\t/\tFALSE\t1359242704\tremixlang\t0\nvk.com\tFALSE\t/\tFALSE\t1359505589\tremixsid\t142e466aee83ed0997d76ec0ebc8407bffe5cf3f740fbbc6d19853b4cb4a\nvk.com\tFALSE\t/\tFALSE\t1359157249\tremixchk\t5\n"  
    @vk_user_id = "60451236"
    @auth_data = {
      :access_token => @token,
      :expires_in => 86400.seconds.to_i,
      :vk_user_id => @vk_user_id
    }
    @api = VkTools::Api.new :access_token => @token
    @pages = VkTools::Pages.new :cookie => @cookie
  end


  context ".authorize" do
    specify "авторизует пользователя на вконтакте по логину/паролю" do
      VCR.use_cassette('test_api', 
                     :record => :new_episodes,
                     :allow_playback_repeats => true) do
        @api.getUserInfo['user_id'].should_not be_nil
      end
      @api.to_hash[:access_token].should_not be_empty
      @pages.to_hash[:cookie].to_s.should_not be_empty
    end

    it "в случае успешной авторизации запоминает данные в redis" do
      described_class.send("remember_identity", @auth_data, :identity => 79000000000)

      result = described_class.send(:redis).hgetall("vk_tools_79000000000")
      result.should be_a(Hash)
      result['vk_user_id'].should == @vk_user_id
      result['access_token'].should == @token
    end

    it ".authorize в качестве expires_in устанавливает минимальное значение из ответа вконтакте, и установленного пользователем значения" do
      # Т.к. проверяем прямо в редисе спрашивая ttl, может быть так что тест вдруг залочится на пару секунд, и ttl не будет равен expires_in на это кол-во секунд.
      # Поэтому сделаем порог правильного ответа, равного 3 секунды
      threshold = 3.seconds.to_i

      described_class.send("remember_identity", @auth_data, :identity => 79000000000)
      described_class.send(:redis).ttl("vk_tools_79000000000").should be_within(threshold).of(86400)

      described_class.send("remember_identity", @auth_data, :identity => 79000000000, :expires_in => 100)
      described_class.send(:redis).ttl("vk_tools_79000000000").should be_within(threshold).of(100)

      described_class.send("remember_identity", @auth_data, :identity => 79000000000, :expires_in => 100000)
      described_class.send(:redis).ttl("vk_tools_79000000000").should be_within(threshold).of(86400)
    end
  end


  context "success" do
    it ".api позволяет получить api по запомненной авторизации" do
      described_class.send("remember_identity", @auth_data, :identity => 79000000000)
      result = described_class.api(79000000000)
      result = @api
      result.should be_a(VkTools::Api)
      result.to_hash[:access_token].should == @token

      described_class.api(79000000001).should be_nil
    end

    it "позволяет получить pages по запомненной авторизации" do
      described_class.send("remember_identity", @auth_data, :identity => 79000000000)
      result = described_class.pages(79000000000)
      result.should be_a(VkTools::Pages)
      described_class.pages(79000000001).should be_nil
    end

    specify ".identity_exists?" do
      described_class.send("remember_identity", @auth_data, :identity => 79000000000)
      should be_identity_exists(79000000000)
      should_not be_identity_exists(79000000001)
    end

    specify ".forget" do
      described_class.send("remember_identity", @auth_data, :identity => 79000000000)
      should be_identity_exists(79000000000)
      described_class.forget(79000000000)
      should_not be_identity_exists(79000000000)
    end

    specify ".access_token_for" do
      described_class.send("remember_identity", @auth_data, :identity => 79000000000)
      described_class.access_token_for(79000000000).should == @token
    end
  end

  describe "Connection error" do
    before(:each) do
      @token = ""
      @api = VkTools::Api.new :access_token => @token
      @pages = VkTools::Pages.new :cookie => ""
      @vcr_cassette = "test_connection_error"
    end

    it "should process auth error" do
      lambda {
        VCR.use_cassette(@vcr_cassette, :record => :new_episodes) do
          @api.getUserInfo!
        end
      }.should raise_error(VkTools::UserAuthFailed)
    end
  end
end
