require "kuiq/model/job"
require "kuiq/model/paginator"

module Kuiq
  module Model
    class JobManager
      REDIS_PROPERTIES = %w[redis_version uptime_in_days connected_clients used_memory_human used_memory_peak_human]

      attr_accessor :polling_interval
      attr_reader :redis_url, :redis_info, :current_time

      def initialize
        @polling_interval = 1
        @redis_url = Sidekiq.redis { |c| c.config.server_url }
        @redis_info = Sidekiq.default_configuration.redis_info
        @current_time = Time.now.utc
        @processed_stats = []
      end

      def stats
        # do not cache in a variable to ensure getting the latest values when calling methods
        # off of the Status object (e.g. when calling stats.processed)
        Sidekiq::Stats.new
      end

      def processed = stats.processed

      def failed = stats.failed

      def busy = Sidekiq::WorkSet.new.size

      def enqueued = stats.enqueued

      def retries = stats.retry_size

      def scheduled = stats.scheduled_size

      def dead = stats.dead_size

      def retried_jobs
        # Data will get lazy loaded into the table as the user scrolls through.
        # After data is built, it is cached long-term, till updating table `cell_rows`.
        sorted_jobs(Sidekiq::RetrySet)
      end

      def scheduled_jobs
        sorted_jobs(Sidekiq::ScheduledSet)
      end

      def dead_jobs
        sorted_jobs(Sidekiq::DeadSet)
      end

      def sorted_jobs(klass)
        inst = klass.new
        key = inst.name
        count = inst.size
        page_size = 25
        page_data_cache = nil
        Enumerator::Lazy.new(count.times, count) do |yielder, index|
          page_index = index / page_size
          page = page_index + 1
          index_within_page = index % page_size
          count = 1
          page_data_cache = nil if index_within_page == 0
          page_data_cache ||= Paginator.instance.page(key, page, page_size)
          job_redis_hash_json, score = page_data_cache.last.reject { |j| j.is_a?(Numeric) }[index_within_page]
          if job_redis_hash_json
            job_redis_hash = JSON.parse(job_redis_hash_json)
            yielder << Job.new(job_redis_hash, score, index)
          end
        end
      end

      def refresh
        refresh_time
        refresh_stats
        refresh_redis_properties
      end

      def refresh_time
        @current_time = Time.now.utc
        notify_observers(:current_time)
      end

      def refresh_stats
        Job::STATUSES.each do |status|
          # notify_observers is added automatically by Glimmer when data-binding
          # it enables manually triggering data-binding changes when needed
          notify_observers(status)
        end
      end

      def refresh_redis_properties
        REDIS_PROPERTIES.each do |property|
          # notify_observers is added automatically by Glimmer when data-binding
          # it enables manually triggering data-binding changes when needed
          redis_info.notify_observers(property)
        end
      end
      
      def record_stats
        @processed_stats.prepend({time: Time.now.utc.strftime("%H:%M:%S UTC"), processed: processed})
        @processed_stats = @processed_stats[0, 61]
      end

      def report_points
        points = []
        current_jobs = @processed_stats
        return points if current_jobs.size <= 1
        current_jobs.each_with_index do |job, n|
          next if n == 0
          jobs_processed = current_jobs[n-1][:processed] - job[:processed]
          jobs_processed = [jobs_processed, GRAPH_MAX_PROCESSED].min
          x = GRAPH_WIDTH - ((n - 1) * GRAPH_POINT_DISTANCE) - GRAPH_PADDING_WIDTH
          y = ((GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT) - jobs_processed*((GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT*2)/GRAPH_MAX_PROCESSED))
          points << [x, y]
        end
        translate_points(points)
        points
      end

      def translate_points(points)
        max_job_count_before_translation = ((GRAPH_WIDTH / GRAPH_POINT_DISTANCE).to_i + 1)
        x_translation = [(points.size - max_job_count_before_translation) * GRAPH_POINT_DISTANCE, 0].max
        if x_translation > 0
          points.each do |point|
            point[0] = point[0] - x_translation
          end
        end
      end
    end
  end
end
