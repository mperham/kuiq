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

      def next_retry
        next_retry_time = sorted_entry.at
        time_duration_until_next_retry = (next_retry_time - Time.now).to_i
        if time_duration_until_next_retry < 0
          "Just now"
        elsif time_duration_until_next_retry < 10
          "Right now"
        else
          chronic_output = ChronicDuration.output(time_duration_until_next_retry, format: :short)
          "In #{chronic_output}"
        end
      end
      alias_method :when, :next_retry

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
        super || redis_hash.include?(method_name.to_s)
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
