require 'remote_logger'

 uri = ARGV[0]

logger = RemoteLogger::DrbLogger.find( verbose: true, uri: uri )

p DRb.config
p uri, "Found", logger

logger.info "OK, here comes something to #{uri}"