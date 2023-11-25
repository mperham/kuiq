module Model
  class Job
    STATUSES = %i[processed failed busy enqueued retries scheduled dead]
    
    attr_accessor :id, :status, :time
  end
end
