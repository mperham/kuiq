require "kuiq/model/job"
require "kuiq/model/process"
require "kuiq/model/work"
require "kuiq/model/paginator"

module Kuiq
  module Model
    class JobManager
      REDIS_PROPERTIES = %w[redis_version uptime_in_days connected_clients used_memory_human used_memory_peak_human]
      BUSY_PROPERTIES = %i[process_size total_concurrency busy utilization total_rss]

      attr_accessor :polling_interval
      attr_reader :redis_url, :redis_info, :current_time

      def initialize
        @polling_interval = POLLING_INTERVAL_DEFAULT
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

      def processes
        process_set.to_a.map { |process_hash| Process.new(process_hash) }
      end

      def works
        work_set.to_a.map { |*args| Work.new(*args) }
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
        page_size = 25
        page_data_cache = nil
        Enumerator::Lazy.new(count.times, count) do |yielder, index|
          page_index = (index / page_size)
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
        refresh_busy_properties
      end

      def refresh_busy_properties
        BUSY_PROPERTIES.each do |property|
          notify_observers(property)
        end
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
    end
  end
end
