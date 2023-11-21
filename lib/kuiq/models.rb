# Models

class Job
  STATUSES = {
    Processed: :processed, Failed: :failed,
    Busy: :busy, Enqueued: :enqueued,
    Retries: :retries, Scheduled: :scheduled, Dead: :dead
  }
  attr_accessor :id, :status, :time
end

class JobManager
  attr_accessor :jobs, :polling_interval
  attr_reader :redis_url, :current_time, :docs_url, :locale, :locale_url, :redis_info

  def initialize
    @current_time = Time.now
    @jobs = []
    @polling_interval = 5
    @redis_url = Sidekiq.redis { |c| c.config.server_url }
    @current_time = Time.now.utc
    @docs_url = "https://github.com/sidekiq/sidekiq/wiki"
    @locale_url = "https://github.com/sidekiq/sidekiq/"
    @locale = "en"
    @redis_info = Sidekiq.default_configuration.redis_info
  end

  def stats
    @stats ||= Sidekiq::Stats.new
  end

  def processed = stats.processed

  def failed = stats.failed

  def busy = Sidekiq::WorkSet.new.size

  def enqueued = stats.enqueued

  def retries = stats.retry_size

  def scheduled = stats.scheduled_size

  def dead = stats.dead_size

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
