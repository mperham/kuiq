require "date"

require "kuiq/model/job_manager"
require "kuiq/model/job"

module Kuiq
  module Model
    class DashboardGraphPresenter
      JOB_STATUSES = [:failed, :processed]
      DAY_IN_SECONDS = 60*60*24

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
      
      def report_history_stats(job_status, day_count)
        reported_stats = {
          x_interval_in_seconds: DAY_IN_SECONDS,
          y_values: [],
          x_value_format: ->(time) { time.strftime('%Y-%m-%d') },
        }
        history_stats = history(day_count: day_count).send(job_status)
        return reported_stats if history_stats.size <= 1
        history_stats.each_with_index do |stat, n|
          formatted_time = stat.first
          time = DateTime.strptime(formatted_time, '%Y-%m-%d').to_time
          value = stat.last
          reported_stats[:x_value_start] = time if n == 0
          reported_stats[:y_values] << value
        end
        reported_stats
      end

      def history(day_count:)
        Sidekiq::Stats::History.new(day_count)
      end

      private

      def live_poll_time_format(time)
        time.strftime("%a %d %b %Y %T GMT")
      end
    end
  end
end
