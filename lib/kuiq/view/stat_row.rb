require "kuiq/view/stat"

module Kuiq
  module View
    class StatRow
      include Glimmer::LibUI::CustomControl

      option :group_title
      option :model
      option :attributes

      body {
        group(group_title) {
          margined false

          horizontal_box {
            attributes.each do |attribute|
              stat(model: model, attribute: attribute)
            end
          }
        }
      }
    end
  end
end
