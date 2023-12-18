module Kuiq
  module Model
    class Work
      attr_reader :process, :thread, :job
      def initialize(process, thread, hash)
        @process = process
        @thread = thread
        @job = hash
      end

      def method_missing(method_name, *args, &block)
        if @job["payload"].include?(method_name.to_s)
          @job["payload"][method_name.to_s]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        super || @job["payload"].include?(method_name.to_s)
      end

      def started_at
        Time.at(job["run_at"])
      end
    end
  end
end
