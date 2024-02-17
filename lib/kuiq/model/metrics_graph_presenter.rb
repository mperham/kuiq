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
      
      def report_metrics_3d_for_selected_job
        the_metrics = job_manager.metrics_for_selected_job
        start_x = the_metrics[:ends_at]
        n = -60
        y_values = the_metrics[:bucket_intervals][1, 10]
        metrics_3d = the_metrics[:job_results].hist.map do |x_value_string, z_values_raw|
          x_value = start_x + (n += 60)
          z_values = z_values_raw[-11..-2].reverse
          [x_value, (y_values.zip(z_values).to_h)]
        end.to_h
        all_z_values = metrics_3d.values.map(&:values).flatten
        max_z_value = all_z_values.max
        min_z_value = all_z_values.reject { |z_value| z_value == 0 }.min || 0.0
        z_value_range = max_z_value - min_z_value
        max_bubble_radius = graph_width / 160.0
        z_normalizer_multiplier = max_bubble_radius / z_value_range.to_f
        normalized_metrics_3d = metrics_3d.map do |x_value, y_z_values|
          normalized_y_z_values = y_z_values.map do |y_value, z_value|
            normalized_z_value = (z_value * z_normalizer_multiplier.to_f) + 1.5
            [y_value, normalized_z_value]
          end.to_h
          [x_value, normalized_y_z_values]
        end.to_h
        normalized_metrics_3d
      end
    end
  end
end
