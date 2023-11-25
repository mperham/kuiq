require "kuiq/model/job"
require "kuiq/view/global_stat"

module View
  class GlobalStats
    include Glimmer::LibUI::CustomControl
  
    option :model
    option :attributes
  
    body {
      horizontal_box {
        attributes.each do |attribute|
          global_stat(model: model, attribute: attribute)
        end
      }
    }
  end
end
