module Model
  class Job
    STATUSES = {
      Processed: :processed, Failed: :failed,
      Busy: :busy, Enqueued: :enqueued,
      Retries: :retries, Scheduled: :scheduled, Dead: :dead
    }
    attr_accessor :id, :status, :time
  end
end
