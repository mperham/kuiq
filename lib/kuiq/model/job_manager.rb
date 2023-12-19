require "kuiq/model/job"
require "kuiq/model/process"
require "kuiq/model/work"
require "kuiq/model/paginator"
require "kuiq/model/queue"
require "kuiq/model/class_metric"

module Kuiq
  module Model
    class JobManager
      REDIS_PROPERTIES = %w[redis_version uptime_in_days connected_clients used_memory_human used_memory_peak_human]
      BUSY_PROPERTIES = %i[process_size total_concurrency busy utilization total_rss]

      attr_accessor :polling_interval, :live_poll
      attr_reader :redis_url, :redis_info, :current_time,
                  :retry_filter, :schedule_filter, :dead_filter,
                  :work_queue_filter

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
        work_objects = work_set.to_a.map { |args| Work.new(*args) }
        work_objects = work_objects.select { |work| work.queue == work_queue_filter } if !work_queue_filter.to_s.strip.empty?
        work_objects
      end
      
      def work_queue_filter=(string)
        @work_queue_filter = string
        notify_observers(:works)
      end

      def queues
        Sidekiq::Queue.all.map { |q| Kuiq::Model::Queue.new(q) }
      end

      def metrics
        query = Sidekiq::Metrics::Query.new
        query_result = query.top_jobs(minutes: 60)
        query_result.job_results.sort_by { |(kls, jr)| -jr.totals["s"] }.take(30).map { |(kls, jr)| Kuiq::Model::ClassMetric.new(kls, jr) }
      end

      def retried_jobs
        # Data will get lazy loaded into the table as the user scrolls through.
        # After data is built, it is cached long-term, till updating table `cell_rows`.
        sorted_jobs(Sidekiq::RetrySet)
      end
      
      def retry_filter=(string)
        @retry_filter = string
        notify_observers(:retried_jobs)
      end

      def scheduled_jobs
        sorted_jobs(Sidekiq::ScheduledSet)
      end
      
      def schedule_filter=(string)
        @schedule_filter = string
        notify_observers(:scheduled_jobs)
      end

      def dead_jobs
        sorted_jobs(Sidekiq::DeadSet)
      end
      
      def dead_filter=(string)
        @dead_filter = string
        notify_observers(:dead_jobs)
      end

      def sorted_jobs(klass)
        inst = klass.new
        key = inst.name
        count = inst.size
        filter_method_name = "#{key}_filter"
        filter = send(filter_method_name) if respond_to?(filter_method_name)
        page_size = 25
        if !filter.to_s.strip.empty?
          result_set = inst.scan(filter).to_a
          job_cache = result_set.each_with_index.map do |sorted_entry, index|
            Job.new(JSON.parse(sorted_entry.value), sorted_entry.score, index)
          end
          count = job_cache.size
          Enumerator::Lazy.new(count.times, count) do |yielder, index|
            yielder << job_cache[index]
          end
        else
          page_data_cache = nil
          Enumerator::Lazy.new(count.times, count) do |yielder, index|
            page_index = (index / page_size)
            page = page_index + 1
            index_within_page = index % page_size
            page_data_cache = nil if index_within_page == 0
            page_data_cache ||= Paginator.instance.page(key, page, page_size)
            job_redis_hash_json, score = page_data_cache.last.reject { |j| j.is_a?(Numeric) }[index_within_page]
            if job_redis_hash_json
              job_redis_hash = JSON.parse(job_redis_hash_json)
              job = Job.new(job_redis_hash, score, index)
              yielder << job
            end
          end
        end
      end

      def refresh
        clear_caches
        refresh_time
        refresh_stats
        refresh_redis_properties
        refresh_busy_properties
        refresh_collections
      end
      
      def clear_caches
        @process_set = @work_set = @stats = nil
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
      
      def refresh_collections
        return unless live_poll
        
        notify_observers(:retried_jobs)
        notify_observers(:scheduled_jobs)
        notify_observers(:dead_jobs)
        notify_observers(:processes)
        notify_observers(:works)
      end
    end
  end
end
