require 'json'

module Kuiq
  module Model
    class Work
      attr_reader :process, :thread, :job, :payload
      def initialize(process, thread, hash)
        @process = process
        @thread = thread
        @job = hash
        @payload = JSON.parse(@job["payload"])
      end
      
      def queue
        job["queue"]
      end
      
      def started_at
        Time.at(job["run_at"]).utc.iso8601
      end
      
      def job_class
        payload["class"]
      end

      def method_missing(method_name, *args, &block)
        if payload.include?(method_name.to_s)
          payload[method_name.to_s]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        super || payload.include?(method_name.to_s)
      end
    end
  end
end
