# @author Dmitry Savelev
# Класс реализует обертку для вызова методов rest api контакта
class VkTools::Api
  include VkTools::Base

  # @param [Hash] params хэш параметров
  # @note :access_token - обязательный параметр
  def initialize(params = {})
    @access_token = params[:access_token]
    @service_name = params[:service_name] || "VkApi"
    @service_adress = params[:service_address] || "api.vkontakte.ru"
    @service_path = params[:service_path] || "/method"
    @service_port = params[:service_port] || 443
    @use_ssl = params[:use_ssl] || true
    @method_as_param = params[:method_as_param] || false

    @ignore_exception = params[:ignore_exception] || false
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
      log_exception exc if method.to_s.ends_with?('!')
      nil
#      super
    end
  end

  protected

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
      method_as_string = method.to_s.gsub('!', '')
      if @method_as_param
        @params[:method] = method_as_string.gsub("_", ".")
      else
        @full_service_path = "#{@service_path}/#{method_as_string.gsub("_", ".")}"
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
              hash[k.to_sym] = Array === v ? v : symbolize_keys(v)
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
      http = Net::HTTP.new(@service_adress, @service_port)
      http.use_ssl = @use_ssl
      path = "#{@full_service_path}?#{query_string}"

      resp, data = http.get(path)

      unless resp.code_type == Net::HTTPOK
        message = "Bad response from #{@service_address}: #{resp.code}"
        raise VkTools::ConnectionError, message
      end

      return data unless data =~ /^[\{|\[].*[\}|\]]$/
      attributes = JSON.parse(data)

      attributes.keys.each do |key|
        raise_exception(attributes[key].clone) if key.to_s =~ /.*error.*/
      end if attributes.is_a?(Hash)

      attributes.include?("response") ? attributes["response"] : attributes
    end

    def raise_exception(attrs)
      vk_error_code = attrs.delete('error_code')

      klass = case vk_error_code
        when 1
          VkTools::UnknownError
        when 2
          VkTools::ApplicationDisabled
        when 4
          VkTools::IncorrectSignature
        when 5
          VkTools::UserAuthFailed
        when 6
          VkTools::TooManyRequestsPerSecond
        when 7
          VkTools::PermissionDenied
        when 100
          VkTools::ParameterMissingOrInvalid
        when 14
          VkTools::CaptchaNeeded
        else
          VkTools::ResponseError
      end

      message = attrs.delete('error_msg')
      exc = klass.new(message)

      exc.vk_error_code  = vk_error_code
      exc.request_params = attrs.delete('request_params')
      exc.payload        = attrs

      raise exc
    end
end
