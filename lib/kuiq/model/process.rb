module Kuiq
  module Model
    class ProcessSet
      def initialize
        @ps = Sidekiq::ProcessSet.new
      end

      def each
        @ps.each do |hash|
          yield Kuiq::Process.new(hash)
        end
      end

      def method_missing(...)
        @ps.send(...)
      end
    end

    class Process
      def initialize(hash)
        @hash = hash
      end

      def method_missing(attr)
        @hash[attr.to_s]
      end
    end
  end
end
