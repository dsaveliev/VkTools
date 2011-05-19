# @author Dmitry Savelev
# Класс реализует обертку для вызова методов rest api контакта
class VkTools::Api
  include VkTools::Base

  # @param [Hash] params хэш параметров
  # @note :access_token - обязательный параметр
  def initialize(params = {})
    @access_token = params[:access_token]
    @service_name = params[:service_name] || "VkApi"
    @service_address = params[:service_address] || "api.vkontakte.ru"
    @service_path = params[:service_path] || "/method"
    @service_port = params[:service_port] || 443
    @use_ssl = params[:use_ssl] || true
    @method_as_param = params[:method_as_param] || false
  end

  # Возвращение хэша с токеном
  # @return [Hash] возврщает хэш с токеном (:access_token)
  def to_hash
    { :access_token => @access_token }
  end

  # Динамический вызов методов rest api контакта: 
  # {http://vkontakte.ru/developers.php?o=-1&p=%CE%EF%E8%F1%E0%ED%E8%E5%20%EC%E5%F2%EE%E4%EE%E2%20API}
  # @return [Hash] возврщает хэш с результатами
  def method_missing(method, *args)
    begin
      initialise_params
      convert_args_to_params(args.first)
      convert_method_to_params(method)
      escape_args
      response = send_request
      return response if response
    rescue Exception => exc
      log_exception(exc)
      super
    end
  end

  private

    def initialise_params
      @args = []
      @params = { :access_token => @access_token }
    end

    def convert_args_to_params(args)
      return unless args
      @args = []
      args.each do |k,v|
        @params[k] = case v
          when Array then v.join(',')
          else v.to_s
        end
        @args << k
      end
    end

    def convert_method_to_params(method)
      if @method_as_param
        @params[:method] = method.to_s.gsub("_", ".")
      else
        @full_service_path = "#{@service_path}/#{method.to_s.gsub("_s_", "/").gsub("_d_", ".")}"
      end
    end

    def escape_args
      @args.each do |k|
        @params[k] = CGI.escape(@params[k])
      end
    end

    def symbolize_keys(data)
      data = [data] if Hash === data
      return data unless Array === data
      response = []
      data.each do |item|
        response << case item
          when Array then
            symbolize_keys item
          when Hash then
            hash = {}
            item.each do |k,v|
              hash[k.to_sym] = Array === v ? symbolize_keys(v) : v
            end
            hash
          else item
        end
      end
      response.size == 1 ? response.first : response
    end

    def send_request
      query_string = @params.
                        map{|arg| "#{arg[0]}=#{arg[1]}"}.
                        join('&')
      http = Net::HTTP.new(@service_address, @service_port)
      http.use_ssl = @use_ssl
      path = "#{@full_service_path}?#{query_string}"

      resp, data = http.get(path)

      unless resp.code_type == Net::HTTPOK
        log_exception("Bad response from #{@service_address}: #{resp.code}")
        return
      end

      return data unless data =~ /^[\{|\[].*[\}|\]]$/
      attributes = JSON.parse(data)

      attributes.keys.each do |key|
        if key.to_s =~ /.*error.*/
          log_exception("#{@service_name} request error: #{attributes[key].inspect}")
          return
        end
      end if Hash === attributes

      case attributes
        when Array then
          return symbolize_keys attributes
        when Hash then
          if attributes.has_key?("response")
            return symbolize_keys attributes["response"]
          else
            return symbolize_keys attributes
          end
        else return attributes
      end
    end
end
