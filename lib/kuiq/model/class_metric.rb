module Kuiq
  module Model
    class ClassMetric
      SWATCHES = [
        "#537bc4", "#4dc9f6", "#f67019", "#f53794", "#acc236",
        "#166a8f", "#00a950", "#58595b", "#8549ba", "#991b1b"
      ]

      attr_reader :name, :results
      def initialize(klass, results)
        @name = klass
        @results = results
      end

      def success = rounded_number(results.dig("totals", "p") - results.dig("totals", "f"))

      def failure = rounded_number(results.dig("totals", "f"))

      def tet = rounded_number(results.dig("totals", "s"), precision: 2)

      def aet = rounded_number(results.total_avg("s"), precision: 2)

      def swatch_background
        SWATCHES.sample
      end

      def swatch
      end

      def swatch=(value)
        value
      end

      private

      def rounded_number(number, options = {})
        precision = options[:precision] || 0
        number.round(precision)
      end
    end
  end
end
