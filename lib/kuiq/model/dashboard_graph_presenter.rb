require "date"

require "kuiq/model/job_manager"
require "kuiq/model/job"

module Kuiq
  module Model
    class DashboardGraphPresenter
      JOB_STATUSES = [:processed, :failed]

      attr_reader :job_manager
      attr_accessor :graph_width

      def initialize(job_manager, graph_width)
        @job_manager = job_manager
        @graph_width
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
      
      def visible_stats
        @stats[0, graph_max_points]
      end
      
      def graph_max_points = (graph_width / GRAPH_POINT_DISTANCE).to_i + 1
      
      def report_points(job_status)
        points = []
        current_stats = visible_stats
        return points if current_stats.size <= 1
        graph_max = [job_status_max, 1].max
        current_stats.each_with_index do |stat, n|
          next if n == 0
          job_status_diff_value = current_stats[n - 1][job_status] - stat[job_status]
          x = graph_width - ((n - 1) * GRAPH_POINT_DISTANCE) - GRAPH_PADDING_WIDTH
          y = ((GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT) - job_status_diff_value * ((GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT * 2) / graph_max))
          points << {x: x, y: y, time: stat[:time], job_status => job_status_diff_value}
        end
        translate_points(points)
        points
      end

      def grid_marker_points
        graph_max = [job_status_max, 1].max
        graph_height = (GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT * 2)
        division_height = graph_height / graph_max
        graph_max.times.map do |marker_index|
          x = GRAPH_PADDING_WIDTH
          y = GRAPH_PADDING_HEIGHT + marker_index * division_height
          {x: x, y: y}
        end
      end

      def job_status_max
        max = 0
        current_stats = visible_stats
        current_stats.each_with_index do |job, n|
          next if n == 0
          JOB_STATUSES.each do |job_status|
            job_status_diff_value = current_stats[n - 1][job_status] - job[job_status]
            max = job_status_diff_value if job_status_diff_value > max
          end
        end
        max
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
          y = ((GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT) - value*((GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT*2)/graph_max))
          raw_time = DateTime.strptime(time, '%Y-%m-%d').to_time
          points << {x: x, y: y, time: time, raw_time: raw_time, job_status => value}
        end
        points
      end
      
      def multi_day_grid_marker_points(day_count)
        graph_max = [multi_day_job_status_max(day_count), 1].max
        graph_height = (GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT*2)
        division_height = graph_height / graph_max
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

      def translate_points(points)
        max_job_count_before_translation = ((graph_width / GRAPH_POINT_DISTANCE).to_i + 1)
        x_translation = [(points.size - max_job_count_before_translation) * GRAPH_POINT_DISTANCE, 0].max
        if x_translation > 0
          points.each do |point|
            # need to check if point[0] is present because if the user shrinks the window, we drop points
            point[0] = point[0] - x_translation if point[0]
          end
        end
      end

      def live_poll_time_format(time)
        time.strftime("%a %d %b %Y %T GMT")
      end
    end
  end
end
