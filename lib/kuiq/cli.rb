require "singleton"
require "optparse"
require "sidekiq"
require "sidekiq/api"
require "kuiq/version"
require "kuiq/i18n"
require "glimmer-dsl-libui"

module Kuiq
  class CLI
    include Singleton

    DEFAULTS = {
      verbose: false,
      action: :gui
    }

    def parse
      @options = DEFAULTS.dup
      OptionParser.new do |opts|
        opts.banner = "Usage: #{opts.program_name} [options]"
        opts.on("-v", "Use verbose logging") do |v|
          @options[:verbose] = v
        end
      end.parse!

      logger.level = (@options[:verbose] ? :info : :warn)
      @options
    end

    def gui
      require "kuiq/gui"
      Kuiq::GUI.launch
    end

    def run
      logger.info { "Kuiq #{Kuiq::VERSION}, using the #{I18n.current_locale.upcase} locale" }
      logger.info { RUBY_DESCRIPTION }
      logger.info { "Redis client #{RedisClient::VERSION}, server #{Sidekiq.default_configuration.redis_info["redis_version"]}" }
      logger.info { "LibUI #{::LibUI::VERSION}, Glimmer <unknown>" }

      send(@options[:action])
    end

    def logger
      Sidekiq.logger
    end
  end
end
