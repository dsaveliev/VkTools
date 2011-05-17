require 'spec_helper'

describe "VkTools" do
  pending(">> NEED A REAL EMAIL AND PASSWORD!") do
    it "integration test" do
      VkTools.client_id = "2046271"
      VkTools.client_secret = "N1wu3hhKJ9HGsjuN7pfS"
      
      login = "******"
      password = "******"
      
      VkTools.authorize(login, password) do |api, pages|
        api.getUserInfo[:user_id].should_not == nil
        pages.get('http://m.vkontakte.ru').include?('В Контакте').should == true
        api.to_hash[:access_token].to_s.empty?.should == false
        pages.to_hash[:cookie].to_s.empty?.should == false
      end
    end
  end
end

