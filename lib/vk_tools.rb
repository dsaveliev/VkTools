module VkTools
  class << self
    def get_api(token)
      VkTools::Api.new :access_token => token    
    end  
  end
end
