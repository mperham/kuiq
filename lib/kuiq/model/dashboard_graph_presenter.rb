require "date"

require "kuiq/model/job_manager"
require "kuiq/model/job"

module Kuiq
  module Model
    class DashboardGraphPresenter
      JOB_STATUSES = [:failed, :processed]

      attr_reader :job_manager
      attr_accessor :graph_width, :graph_height

      def initialize(job_manager, graph_width, graph_height)
        @job_manager = job_manager
        @graph_width = graph_width
        @graph_height = graph_height
        @stats = []
        @multi_day_stats = []
        @reset_stats_observer = Glimmer::DataBinding::Observer.proc { @stats = [] }
        @reset_stats_observer.observe(@job_manager, :polling_interval)
      end

      def record_stats
        raw_time = Time.now.utc
        stat = {
          time: live_poll_time_format(raw_time),
          raw_time: raw_time,
          processed: job_manager.processed,
          failed: job_manager.failed
        }
        @stats.prepend(stat)
        @stats = @stats[0, GRAPH_MAX_POINTS_LARGEST_SCREEN]
      end
      
      def report_stats(job_status)
        reported_stats = {
          x_interval_in_seconds: @job_manager.polling_interval,
          y_values: [],
          x_value_format: ->(time) { live_poll_time_format(time) },
        }
        return reported_stats if @stats.size <= 1
        @stats.each_with_index do |stat, n|
          if n == 0
            reported_stats[:x_value_start] = stat[:raw_time]
            next
          end
          y_value = @stats[n - 1][job_status] - stat[job_status]
          reported_stats[:y_values] << y_value
        end
        reported_stats
      end

      def multi_day_history(day_count)
        Sidekiq::Stats::History.new(day_count)
      end
      
      def multi_day_report_points(day_count, job_status)
        @multi_day_stats = multi_day_history(day_count).send(job_status)
        points = []
        return points if @multi_day_stats.size <= 1
        graph_max = [multi_day_job_status_max(day_count), 1].max
        @multi_day_stats.each_with_index do |stat, n|
          time = stat.first
          value = stat.last
          x = graph_width - (n * multi_day_graph_point_distance(day_count)) - GRAPH_PADDING_WIDTH
          y = ((graph_height - GRAPH_PADDING_HEIGHT) - value*((graph_height - GRAPH_PADDING_HEIGHT*2)/graph_max))
          raw_time = DateTime.strptime(time, '%Y-%m-%d').to_time
          points << {x: x, y: y, time: time, raw_time: raw_time, job_status => value}
        end
        points
      end
      
      def multi_day_grid_marker_points(day_count)
        graph_max = [multi_day_job_status_max(day_count), 1].max
        current_graph_height = (graph_height - GRAPH_PADDING_HEIGHT*2)
        division_height = current_graph_height / graph_max
        graph_max.times.map do |marker_index|
          x = GRAPH_PADDING_WIDTH
          y = GRAPH_PADDING_HEIGHT + marker_index * division_height
          {x: x, y: y}
        end
      end
      
      def multi_day_job_status_max(day_count)
        history = multi_day_history(day_count)
        JOB_STATUSES.map { |job_status| history.send(job_status).values }.reduce(:+).max
      end
      
      def multi_day_graph_point_distance(day_count)
        (graph_width - 2.0*GRAPH_PADDING_WIDTH - 30) / (day_count-1).to_f
      end

      private

      def live_poll_time_format(time)
        time.strftime("%a %d %b %Y %T GMT")
      end
    end
  end
end
