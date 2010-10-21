require 'remote_logger'

logger = RemoteLogger::RingyLogger.start( verbose: true, uri: ARGV[0])
