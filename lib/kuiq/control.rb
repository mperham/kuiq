module Kuiq
  module Control
    def self.included(base)
      base.send(:include, Glimmer::LibUI::CustomControl)
    end

    LOCALES = "./locales"

    # Dont know anything about Glimmer::LibUI::Application!?
    # Does it have a logger?
    def logger
      Sidekiq.logger
    end

    # Use Sidekiq's i18n with locale files in sidekiq/web/locales
    # Note task in Rakefile to refresh locale files.
    def current_locale
      @@locale ||= begin
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
      @@strings ||= {}
      @@strings[lang] ||= [LOCALES].each_with_object({}) do |path, global|
        Dir["#{path}/#{lang}.yml"].each do |file|
          strs = YAML.safe_load_file(file)
          global.merge!(strs[lang])
        end
      end
    end
  end
end
