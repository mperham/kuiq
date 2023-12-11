module Kuiq
  module Model
    class Queue
      def initialize(q)
        @q = q
      end

      def name = "#{@q.name}#{@q.paused? ? " 🛑" : ""}"

      def size = @q.size

      def latency = rounded_number(@q.latency, precision: 1)

      def paused? = @q.paused?

      def actions = ""

      private

      def rounded_number(number, options = {})
        precision = options[:precision] || 0
        number.round(precision)
      end
    end
  end
end
