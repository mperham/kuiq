module Kuiq
  module Model
    class ClassMetric
      attr_reader :name, :results
      def initialize(klass, results)
        @name = klass
        @results = results
      end

      def success = rounded_number(results.dig("totals", "p") - results.dig("totals", "f"))

      def failure = rounded_number(results.dig("totals", "f"))

      def tet = rounded_number(results.dig("totals", "s"), precision: 2)

      def aet = rounded_number(results.total_avg("s"), precision: 2)

      private

      def rounded_number(number, options = {})
        precision = options[:precision] || 0
        number.round(precision)
      end
    end
  end
end
