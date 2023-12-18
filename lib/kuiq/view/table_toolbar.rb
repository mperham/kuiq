module Kuiq
  module View
    class TableToolbar
      include Glimmer::LibUI::CustomControl
  
      option :job_manager
      option :include_filter, default: true
      option :filter_name
  
      body {
        horizontal_box {
          checkbox(t('LivePoll')) {
            stretchy false
            
            checked <=> [job_manager, :live_poll]
          }
          
          # filler
          label
          
          if include_filter
            label("#{t('Filter')}:") {
              stretchy false
            }
            
            entry {
              stretchy false
              
              text <=> [job_manager, "#{filter_name}_filter"]
            }
          end
        }
      }
  
    end
  end
end
