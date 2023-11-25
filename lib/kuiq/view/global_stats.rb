require "kuiq/model/job"
require "kuiq/view/global_stat"

module View
  class GlobalStats
    include Glimmer::LibUI::CustomControl
  
    option :job_manager
  
    body {
      horizontal_box {
        stretchy false
  
        Model::Job::STATUSES.each_pair do |k, v|
          global_stat(job_manager: job_manager, k:, v:)
        end
      }
    }
  end
end
