# @author Dmitry Savelev
# Модуль для вспомогалтельных методов
module VkTools::Base
  # Логирование уровня info
  # @param [String] msg текст исключения
  def log(msg)
    VkTools.logger.info(msg) if self.logger
  end
  # Логирование уровня error
  # @param [Exception, String] exc текст исключения или само исключение
  def log_exception(exc)
    message = "Exception: #{exc.class.to_s} : #{exc.message} \n #{exc.backtrace.join("\n")} \n"
    puts message
    VkTools.logger.error message if self.logger
    raise exc
  end
end
