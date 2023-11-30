module Kuiq
  module Model
    class WorkSet
      def initialize
        @ps = Sidekiq::WorkSet.new
      end

      def each
        @ps.each do |*args|
          yield Kuiq::Work.new(*args)
        end
      end

      def method_missing(...)
        @ps.send(...)
      end
    end

    class Work
      attr_reader :process, :thread, :job
      def initialize(process, thread, hash)
        @process = process
        @thread = thread
        @job = hash
      end

      def method_missing(attr)
        @job["payload"][attr.to_s]
      end

      def started_at
        Time.at(job["run_at"])
      end
    end
  end
end
