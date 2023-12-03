require "kuiq/model/job_manager"
require "kuiq/model/job"

module Kuiq
  module Model
    class DashboardGraphPresenter
      JOB_STATUSES = [:processed, :failed]
      
      attr_reader :job_manager
      
      def initialize(job_manager)
        @job_manager = job_manager
        @stats = []
        @reset_stats_observer = Glimmer::DataBinding::Observer.proc {@stats = []}
        @reset_stats_observer.observe(@job_manager, :polling_interval)
      end
      
      def record_stats
        stat = {
          time: now,
          processed: job_manager.processed,
          failed: job_manager.failed,
        }
        @stats.prepend(stat)
        @stats = @stats[0, GRAPH_MAX_POINTS]
      end

      def report_points(job_status)
        points = []
        return points if @stats.size <= 1
        graph_max = [job_status_max, 1].max
        @stats.each_with_index do |job, n|
          next if n == 0
          job_status_diff_value = @stats[n-1][job_status] - job[job_status]
          x = GRAPH_WIDTH - ((n - 1) * GRAPH_POINT_DISTANCE) - GRAPH_PADDING_WIDTH
          y = ((GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT) - job_status_diff_value*((GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT*2)/graph_max))
          points << [x, y]
        end
        translate_points(points)
        points
      end
      
      def grid_marker_points
        graph_max = [job_status_max, 1].max
        graph_height = (GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT*2)
        division_height = graph_height / graph_max
        graph_max.times.map do |marker_index|
          x = GRAPH_PADDING_WIDTH
          y = GRAPH_PADDING_HEIGHT + marker_index * division_height
          [x, y]
        end
      end
      
      def job_status_max
        max = 0
        @stats.each_with_index do |job, n|
          next if n == 0
          JOB_STATUSES.each do |job_status|
            job_status_diff_value = @stats[n-1][job_status] - job[job_status]
            max = job_status_diff_value if job_status_diff_value > max
          end
        end
        max
      end
      
      private

      def translate_points(points)
        max_job_count_before_translation = ((GRAPH_WIDTH / GRAPH_POINT_DISTANCE).to_i + 1)
        x_translation = [(points.size - max_job_count_before_translation) * GRAPH_POINT_DISTANCE, 0].max
        if x_translation > 0
          points.each do |point|
            point[0] = point[0] - x_translation
          end
        end
      end
      
      def now
        Time.now.utc.strftime("%H:%M:%S UTC")
      end
    end
  end
end
