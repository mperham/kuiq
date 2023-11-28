require "kuiq/model/job"
require "kuiq/model/paginator"

module Kuiq
  module Model
    class JobManager
      REDIS_PROPERTIES = %w[redis_version uptime_in_days connected_clients used_memory_human used_memory_peak_human]

      attr_accessor :jobs, :polling_interval
      attr_reader :redis_url, :redis_info, :current_time

      def initialize
        @jobs = []
        @polling_interval = 5
        @redis_url = Sidekiq.redis { |c| c.config.server_url }
        @redis_info = Sidekiq.default_configuration.redis_info
        @current_time = Time.now.utc
      end

      def stats = @stats ||= Sidekiq::Stats.new

      def process_set = @process_set ||= Sidekiq::ProcessSet.new

      def work_set = @work_set ||= Sidekiq::WorkSet.new

      def processed = stats.processed

      def failed = stats.failed

      def busy = work_set.size

      def enqueued = stats.enqueued

      def retries = stats.retry_size

      def scheduled = stats.scheduled_size

      def dead = stats.dead_size

      def process_size = process_set.size

      def total_concurrency = process_set.total_concurrency

      def total_rss = process_set.total_rss

      def utilization
        x = total_concurrency
        ws = busy
        x.zero? ? 0 : ((ws / x.to_f) * 100).round(0)
      end

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
        refresh_time
        refresh_stats
        refresh_redis_properties
      end

      def refresh_time
        @current_time = Time.now.utc
        notify_observers(:current_time)
      end

      def refresh_stats
        @process_set = @work_set = @stats = nil
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

      def format_memory(rss_kb)
        return "0" if rss_kb.nil? || rss_kb == 0

        if rss_kb < 100_000
          "#{number_with_delimiter(rss_kb)} KB"
        elsif rss_kb < 10_000_000
          "#{number_with_delimiter((rss_kb / 1024.0).to_i)} MB"
        else
          "#{number_with_delimiter((rss_kb / (1024.0 * 1024.0)), precision: 1)} GB"
        end
      end

      def number_with_delimiter(number, options = {})
        precision = options[:precision] || 0
        number.round(precision)
      end
    end
  end
end
