require 'remote_logger'

logger = RemoteLogger::DrbLogger.start( verbose: true, uri: ARGV[0])
