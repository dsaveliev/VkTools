require 'spec_helper'

describe "VkTools" do
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
      :body => '{"response":{"user_id":"60451236","user_name":null}}',
      :status => ["200", "Success"]      
    )

    FakeWeb.register_uri(
      :get,
      'http://m.vkontakte.ru',
      :body => 'В Контакте'  
    )
  end

  it "integration test" do
    VkTools.client_id = "2046271"
    VkTools.client_secret = "N1wu3hhKJ9HGsjuN7pfS"
    
    login = "test"
    password = "test"
    
    VkTools.authorize(login, password) do |api, pages|
      api.getUserInfo[:user_id].should_not == nil
      pages.get('http://m.vkontakte.ru').include?('В Контакте').should == true
      api.to_hash[:access_token].to_s.empty?.should == false
      pages.to_hash[:cookie].to_s.empty?.should == false
    end
  end
end

