module Kuiq
  module Model
    class ClassMetric
      class << self
        def next_swatch_color
          available_swatch_colors[next_swatch_color_index % available_swatch_colors.size]
        end
        
        def available_swatch_colors
          @available_swatch_colors ||= SWATCH_COLORS.dup.shuffle + Glimmer::LibUI.x11_colors.dup.shuffle
        end
        
        private
        
        def next_swatch_color_index
          @next_swatch_color_index ||= -1
          @next_swatch_color_index += 1
        end
      end
    
      SWATCH_COLORS = [
        "#537bc4", "#4dc9f6", "#f67019", "#f53794", "#acc236",
        "#166a8f", "#00a950", "#58595b", "#8549ba", "#991b1b"
      ]

      attr_reader :swatch_name_color, :results
      
      def initialize(klass, results)
        @results = results
        # we need to store data in a triad to match what libui expects of
        # table data in a 3-value checkbox text color column
        @swatch_name_color = [true, klass, ClassMetric.next_swatch_color]
      end

      def success = rounded_number(results.dig("totals", "p") - results.dig("totals", "f"))

      def failure = rounded_number(results.dig("totals", "f"))

      def tet = rounded_number(results.dig("totals", "s"), precision: 2)

      def aet = rounded_number(results.total_avg("s"), precision: 2)

      def swatch
        swatch_name_color[0]
      end

      def name
        swatch_name_color[1]
      end

      def swatch_color
        swatch_name_color[2]
      end

      private

      def rounded_number(number, options = {})
        precision = options[:precision] || 0
        number.round(precision)
      end
    end
  end
end
