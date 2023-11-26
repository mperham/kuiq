require "kuiq/view/global_stats"
require "kuiq/view/status_bar"

module Kuiq
  module View
    class Retries
      include Glimmer::LibUI::CustomControl
    
      option :job_manager
    
      body {
        vertical_box {
          global_stats(model: job_manager, attributes: Model::Job::STATUSES) {
            stretchy false
          }
          
          graphical_label(label_text: 'Retries', width: 200, font_properties: {size: 30})
          
          status_bar(job_manager: job_manager)
        }
      }
    end
  end
end
