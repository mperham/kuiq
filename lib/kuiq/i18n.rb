# frozen_string_literal: true

module Kuiq
  class I18n
    LOCALES = "./locales"
    
    class << self
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
    
      # Translates msg string for current locale (e.g. for "Dashboard", we get "Tableau de Bord" in fr)
      def t(msg, options = {})
        string = strings(Kuiq::I18n.current_locale)[msg] || strings("en")[msg] || msg
        if options.empty?
          string
        else
          string % options
        end
      end
    
      # Inverse-translates msg string for current locale (e.g. for "Tableau de Bord" in fr, we get "Dashboard")
      def it(msg, options = {})
        inverted_strings = strings(Kuiq::I18n.current_locale).invert
        inverted_english_strings = strings("en").invert
        msg_without_underscores = msg.to_s.sub('_', ' ')
        string = inverted_strings[msg] ||
                   inverted_strings[msg_without_underscores] ||
                   inverted_english_strings[msg] ||
                   inverted_english_strings[msg_without_underscores] ||
                   msg
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
  
      # TODO optimize performance with caching
#       private def inverted_strings(lang)
#         @strings ||= {}
#         @strings[lang] ||= [LOCALES].each_with_object({}) do |path, global|
#           Dir["#{path}/#{lang}.yml"].each do |file|
#             strs = YAML.safe_load_file(file)
#             global.merge!(strs[lang])
#           end
#         end
#       end
    end
  end
end
