require "date"

require "kuiq/model/job_manager"

module Kuiq
  module Model
    class MetricsGraphPresenter
      TIME_FORMAT = '%H:%M'
      
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
        values = class_metric.results.series["s"].inject({}) do |output, (time, value)|
          raw_time = DateTime.strptime(time, TIME_FORMAT).to_time
          output.merge(raw_time => value)
        end
        {
          name: class_metric.name,
          stroke: [*class_metric.swatch_color, thickness: 2],
          values: values,
          x_value_format: ->(raw_time) { raw_time.strftime(TIME_FORMAT) },
        }
      end
      
      def report_metrics_for_selected_job
        the_metrics = job_manager.metrics_for_selected_job
        the_metrics[:bucket_labels].zip(the_metrics[:hist_totals]).to_h
      end
    end
  end
end
