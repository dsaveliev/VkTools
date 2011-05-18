# @author Dmitry Savelev
# Класс реализует обертку для доступа к контенту vkontakte.ru
class VkTools::Pages
  include VkTools::Base

  # @param [Hash] params хэш параметров
  # @note :cookie - обязательный параметр
  def initialize(params = {})
    @cookie = params[:cookie]
    @agent = Mechanize.new
    @cookie_jar = @agent.cookie_jar
    @cookie_jar.load_cookies(@cookie)
  end

  # Делает get запрос по указанному адресу
  # @param [String] path url адрес
  # @return [String] код страницы
  # @note url адрес должен быть полным, т.е. начинаться с http://
  def get(path)
    page = @agent.get(path)
    page.body
  end

  # Делает post запрос по указанному адресу
  # @param [Path] path url адрес
  # @param [Hash] params хэш параметров запроса
  # @return [String] код страницы
  # @note url адрес должен быть полным, т.е. начинаться с http://
  def post(path, params)
    page = @agent.post(path, params)
    page.body
  end

  # Делает get запрос по указанному адресу, возвращая Mechanize::Page
  # @param [String] path url адрес
  # @return [Mechanize::Page] объект Mechanize::Page
  # @note url адрес должен быть полным, т.е. начинаться с http://
  def mech_get(path)
    @agent.get(path)
  end

  # Делает post запрос по указанному адресу, возвращая Mechanize::Page
  # @param [Path] path url адрес
  # @param [Hash] params хэш параметров запроса
  # @return [Mechanize::Page] объект Mechanize::Page
  # @note url адрес должен быть полным, т.е. начинаться с http://
  def mech_post(path, params)
    @agent.post(path, params)
  end

  # Возвращение хэша с cookies
  # @return [Hash] возврщает хэш с cookies (:cookie)
  def to_hash
    { :cookie => @cookie_jar.dump_cookies }
  end
end

