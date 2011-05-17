module Auth

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def inner_authorize(login, password)
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
      result = get_access_token(code)
      result.merge!(cookie) if !!result
    end
    
    private

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
    #        MproLogger.mlog("Bad response from api.vk.com: #{resp.code}")
            return
          end

          attributes = JSON.parse(data)

          if attributes.has_key?("error")
    #        MproLogger.mlog("Authentification problem: #{attributes['error']}")
            return
          end
          {
            :access_token => attributes['access_token'],
            :vk_user_id => attributes['user_id'],
            :expires_in => attributes['expires_in']
          }
        rescue Exception => exc
    #      MproLogger.mlog(exc.message)
          return
        end
      end
  end
end
