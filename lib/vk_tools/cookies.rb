class VkTools::Cookies
  def self.to_s(cookie_jar)
    cookie_string_buffer = StringIO.new
    cookie_jar.dump_cookiestxt(cookie_string_buffer)
    cookie_string_buffer.string
  end

  def self.to_jar(text, jar=nil)
    jar ||= Mechanize::CookieJar.new
    jar.load_cookiestxt(StringIO.new(text))
    jar
  end
end
