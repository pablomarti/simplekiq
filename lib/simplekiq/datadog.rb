require 'sidekiq'
require 'sidekiq-datadog'
require 'datadog/statsd'

module Simplekiq
  class Datadog
    class << self
      def config
        Sidekiq.configure_server do |sidekiq_config|
          sidekiq_config.server_middleware do |chain|
            chain.add(
              Sidekiq::Middleware::Server::Datadog,
              tags: [
                ->(_worker, _job, _queue, _error) { "service:#{app_name}" }
              ]
            )
          end

          if defined?(Sidekiq::Pro)
            Sidekiq::Pro.dogstatsd = lambda do
              ::Datadog::Statsd.new(
                ENV.fetch('DATADOG_HOST', 'localhost'),
                ENV.fetch('DATADOG_PORT', 8125)
              )
            end

            sidekiq_config.server_middleware do |chain|
              require 'sidekiq/middleware/server/statsd'
              chain.add Sidekiq::Middleware::Server::Statsd
            end
          end
        end
      end

      def app_name
        Simplekiq.app_name || 'undefined'
      end
    end
  end
end
