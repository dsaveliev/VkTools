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
    return unless !!VkTools.logger
    exc = Exception.new(exc) if String === exc
    VkTools.logger.error "VkTools. " + exc.class.to_s + " : " + exc.message + "\n" + exc.backtrace.join("\n")
  end
end
