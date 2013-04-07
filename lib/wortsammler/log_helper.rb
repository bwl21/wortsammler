# setup the logger
require 'Logger'
$log = Logger.new(STDOUT)
$log.level = Logger::INFO
$log.datetime_format= "%Y-%m-%d %H:%M:%S"          
$log.formatter = proc do |severity, datetime, progname, msg|
  "[#{severity}] #{progname}: #{datetime.strftime($log.datetime_format)}: #{msg}\n"
end
