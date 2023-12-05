module Kuiq
  module Model
    class Process
      def initialize(hash)
        @hash = hash
      end

      def started_at
        Time.at(@hash["started_at"]).utc.iso8601
      end

      def rss
        format_memory(@hash["rss"])
      end

      def method_missing(attr)
        @hash[attr.to_s]
      end

      def respond_to_missing?(attr, include_private = false)
        super || @hash.include?(attr.to_s)
      end

      private

      def format_memory(rss_kb)
        return "0" if rss_kb.nil? || rss_kb == 0

        if rss_kb < 100_000
          "#{rss_kb} KB"
        elsif rss_kb < 10_000_000
          "#{rounded_number((rss_kb / 1024.0).to_i)} MB"
        else
          "#{rounded_number((rss_kb / (1024.0 * 1024.0)), precision: 1)} GB"
        end
      end

      def rounded_number(number, options = {})
        precision = options[:precision] || 0
        number.round(precision)
      end
    end
  end
end
