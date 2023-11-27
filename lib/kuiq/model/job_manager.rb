require "kuiq/model/job"
require "kuiq/model/paginator"

module Kuiq
  module Model
    class JobManager
      REDIS_PROPERTIES = %w[redis_version uptime_in_days connected_clients used_memory_human used_memory_peak_human]

      attr_accessor :jobs, :polling_interval
      attr_reader :redis_url, :current_time, :docs_url, :locale, :locale_url, :redis_info

      def initialize
        @jobs = []
        @polling_interval = 5
        @redis_url = Sidekiq.redis { |c| c.config.server_url }
        @current_time = Time.now.utc
        @docs_url = "https://github.com/sidekiq/sidekiq/wiki"
        @locale_url = "https://github.com/sidekiq/sidekiq/tree/main/web/locales"
        @locale = "en"
        @redis_info = Sidekiq.default_configuration.redis_info
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
        key = "retry"
        count = retries
        Enumerator::Lazy.new(count.times, count) do |yielder, index|
          page = index + 1
          count = 1
          job_redis_hash_json, score = Paginator.instance.page(key, page, 1).last.reject { |j| j.is_a?(Numeric) }.first
          if job_redis_hash_json
            job_redis_hash = JSON.parse(job_redis_hash_json)
            yielder << Job.new(job_redis_hash, score, index)
          end
        end
      end

      def refresh
        @current_time = Time.now.utc
        refresh_stats
        refresh_redis_properties
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

      def report_points
        points = []
        current_jobs = jobs.dup
        start_time = @current_time
        end_time = Time.now
        time_length = (end_time - start_time).to_i
        time_length.times do |n|
          job_found = current_jobs.detect do |job|
            job_delay = job.time - start_time
            job_delay.between?(n, n + 1)
          end
          x = n * 15
          y = job_found ? 5 : 195
          points << [x, y]
        end
        translate_points(points)
        points
      end

      def translate_points(points)
        max_job_count_before_translation = ((800 / 15).to_i + 1)
        x_translation = [(points.size - max_job_count_before_translation) * 15, 0].max
        if x_translation > 0
          points.each do |point|
            point[0] = point[0] - x_translation
          end
        end
      end
    end
  end
end
