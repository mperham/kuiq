require "kuiq/model/job"
require "kuiq/view/global_stat"

module Kuiq
  module View
    class GlobalStats
      include Glimmer::LibUI::CustomControl

      option :group_title
      option :model
      option :attributes

      body {
        group(group_title) {
          margined false

          horizontal_box {
            attributes.each do |attribute|
              global_stat(model: model, attribute: attribute)
            end
          }
        }
      }
    end
  end
end
