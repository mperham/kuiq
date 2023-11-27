require "sidekiq"
require "sidekiq/api"
require "glimmer-dsl-libui"

require "kuiq"
require "kuiq/model/job_manager"
require "kuiq/view/dashboard"
require "kuiq/view/retries"

module Kuiq
  class SidekiqUI
    include Glimmer::LibUI::Application

    LOCALES = "./locales"

    # Dont know anything about Glimmer::LibUI::Application!?
    # Does it have a logger?
    def logger
      Sidekiq.logger
    end

    # Use Sidekiq's i18n with locale files in sidekiq/web/locales
    # Note task in Rakefile to refresh locale files.
    def current_locale
      @locale ||= begin
        x = (ENV["LANGUAGE"] || ENV["LANG"] || "en").downcase.tr("_", "-")
        loop do
          break "en" if x.size < 2
          break x if File.exist?("#{LOCALES}/#{x}.yml")
          # dumb brute force heuristic: look for locale files
          # that match the longest LANG prefix, necessary to serve
          # more complex lang groups like zh and pt.
          x = x[0...-1]
        end
      end
    end

    def t(msg, options = {})
      string = strings(current_locale)[msg] || strings("en")[msg] || msg
      if options.empty?
        string
      else
        string % options
      end
    end

    private def strings(lang)
      @strings ||= {}
      @strings[lang] ||= [LOCALES].each_with_object({}) do |path, global|
        Dir["#{path}/#{lang}.yml"].each do |file|
          strs = YAML.safe_load_file(file)
          global.merge!(strs[lang])
        end
      end
    end

    before_body do
      logger.info { "Welcome to Kuiq #{Kuiq::VERSION}, using the #{current_locale.upcase} locale" }
      logger.info { RUBY_DESCRIPTION }

      @job_manager = Model::JobManager.new
      logger.info { "Redis client #{RedisClient::VERSION}, server #{@job_manager.redis_info["redis_version"]}" }
    end

    after_body do
      # generate_jobs
    end

    body {
      window("Sidekiq UI", WINDOW_WIDTH, WINDOW_HEIGHT) {
        vertical_box {
          tab {
            tab_item(t("Dashboard")) {
              dashboard(job_manager: @job_manager)
            }
            # TODO enable each tab when implemented (only implemented ones will be visible)
            #           tab_item("Busy") {
            #           }
            #           tab_item("Queues") {
            #           }
            tab_item(t("Retries")) {
              retries(job_manager: @job_manager)
            }
            #           tab_item("Scheduled") {
            #           }
            #           tab_item("Dead") {
            #           }
            #           tab_item("Metrics") {
            #           }
          }
        }
      }
    }
  end
end
