require "date"

require "kuiq/model/job_manager"

module Kuiq
  module Model
    class MetricsGraphPresenter
      attr_reader :job_manager
      attr_accessor :graph_width, :graph_height

      def initialize(job_manager, graph_width, graph_height)
        @job_manager = job_manager
        @graph_width = graph_width
        @graph_height = graph_height
      end
      
      def report_graph_lines
        job_manager.metrics.select(&:swatch).map(&method(:report_graph_line))
      end
      
      def report_graph_line(class_metric)
        reported_graph_lines = {
          name: class_metric.name,
          stroke: [*class_metric.swatch_color, thickness: 2],
          y_values: [],
        }
        series = class_metric.results.series["s"]
        return reported_graph_lines if series.size <= 1
        first_raw_time = first_time = nil
        series.each_with_index do |time_value_pair, n|
          time, value = time_value_pair
          raw_time = DateTime.strptime(time, '%H:%M').to_time
          if n == 0
            first_time = time
            first_raw_time = raw_time
            reported_graph_lines[:x_value_start] = raw_time
            next
          end
          if n == 1
            reported_graph_lines[:x_interval_in_seconds] = first_raw_time - raw_time
          end
          y_value = value
          reported_graph_lines[:y_values] << y_value
        end
        reported_graph_lines
      end
    end
  end
end
