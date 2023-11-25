require "kuiq/view/global_stats"
require "kuiq/view/dashboard_graph"
require "kuiq/view/status_bar"

module View
  class Dashboard
    include Glimmer::LibUI::CustomControl
  
    option :job_manager
  
    body {
      vertical_box {
        global_stats(model: job_manager, attributes: Model::Job::STATUSES) {
          stretchy false
        }
  
        horizontal_box {
          area {
            stretchy false
            
            text(0, 0, 200) {
              default_font size: 30
              string("Dashboard")
            }
          }
  
          # filler
          label
  
          vertical_box {
            horizontal_box {
              label("Polling interval:") {
                stretchy false
              }
  
              label {
                text <= [job_manager, :polling_interval,
                  on_read: ->(val) { "#{val} sec" }]
              }
            }
  
            slider(1, 10) {
              value <=> [job_manager, :polling_interval]
            }
          }
        }
  
        dashboard_graph(job_manager: job_manager)
  
        global_stats(model: job_manager.redis_info, attributes: Model::JobManager::REDIS_PROPERTIES) {
          stretchy false
        }
  
        status_bar(job_manager: job_manager)
      }
    }
  end
end
