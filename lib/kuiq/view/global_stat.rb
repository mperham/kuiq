module View
  class GlobalStat
    include Glimmer::LibUI::CustomControl
    
    ATTRIBUTE_CUSTOM_TEXT = {
      "uptime_in_days" => "Uptime",
      "connected_clients" => "Connections",
      "used_memory_human" => "Used Memory",
      "used_memory_peak_human" => "Peak Used Memory",
    }
  
    option :model
    option :attribute
    
    before_body do
      @attribute_text = ATTRIBUTE_CUSTOM_TEXT[attribute.to_s] || humanize(attribute)
    end
  
    body {
      vertical_box {
        label(@attribute_text)
        
        label {
          text <= [model, attribute, on_read: :to_s]
        }
      }
    }
    
    def humanize(attribute)
      attribute.to_s.split('_').map(&:capitalize).join(' ')
    end
  end
end
