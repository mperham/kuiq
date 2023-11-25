module View
  class GlobalStat
    include Glimmer::LibUI::CustomControl
  
    option :job_manager
    option :k
    option :v
  
    body {
      vertical_box {
        label {
          text <= [job_manager, v,
            on_read: ->(jobs_array) {
              job_manager.send(v).to_s
            }]
        }
  
        label(k.to_s)
      }
    }
  end
end
