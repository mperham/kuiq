require "chronic_duration"
require "json"

module Kuiq
  module Model
    class Job
      STATUSES = %i[processed failed busy enqueued retries scheduled dead]

      attr_reader :redis_hash, :score, :index

      def initialize(redis_hash, score, index = nil)
        @redis_hash = redis_hash
        @score = score
        @index = index
      end

      def at
        Time.at(score).utc
      end

      def at_s
        timeago_in_words(at)
      end
      alias_method :next_retry, :at_s
      alias_method :when, :at_s
      alias_method :last_retry, :at_s

      def job
        redis_hash["class"]
      end

      def arguments
        redis_hash["args"].map { |arg| "\"#{arg}\"" }.join(", ")
      end

      def error
        redis_hash["error_message"]
      end

      def sorted_entry
        @sorted_entry ||= Sidekiq::SortedEntry.new(nil, score, JSON.dump(redis_hash))
      end

      def respond_to_missing?(method_name, include_private = false)
        super ||
          redis_hash.include?(method_name.to_s)
      end

      def method_missing(method_name, *args, &block)
        if redis_hash.include?(method_name.to_s)
          redis_hash[method_name.to_s].to_s
        else
          super
        end
      end
    end
  end
end
