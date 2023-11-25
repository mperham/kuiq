require "kuiq/view/global_stats"
require "kuiq/view/dashboard_graph"
require "kuiq/view/status_bar"

module View
  class Dashboard
    include Glimmer::LibUI::CustomControl
  
    option :job_manager
  
    body {
      vertical_box {
        global_stats(job_manager: job_manager)
  
        horizontal_box {
          label("Dashboard") {
            stretchy false
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
  
        horizontal_box {
          vertical_box {
            label "Redis Version"
            label job_manager.redis_info["redis_version"]
          }
          vertical_box {
            label "Uptime"
            label job_manager.redis_info["uptime_in_days"]
          }
          vertical_box {
            label "Connections"
            label job_manager.redis_info["connected_clients"]
          }
          vertical_box {
            label "Used Memory"
            label job_manager.redis_info["used_memory_human"]
          }
          vertical_box {
            label "Peak Used Memory"
            label job_manager.redis_info["used_memory_peak_human"]
          }
        }
  
        status_bar(job_manager: job_manager)
      }
    }
  end
end
