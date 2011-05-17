class VkTools::Pages
  def initialize(params = {})
    @cookie = params[:cookie]
    @agent = Mechanize.new
    @cookie_jar = @agent.cookie_jar
    @cookie_jar.load_cookies(@cookie)
  end

  def get(path)
    page = @agent.get(path)
    page.body
  end

  def post(path, params)
    page = @agent.post(path, params)
    page.body
  end

  def to_hash
    { :cookie => @cookie_jar.dump_cookies }
  end
end
