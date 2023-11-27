require "kuiq/model/job"
require "kuiq/view/global_stat"

module Kuiq
  module View
    class GlobalStats
      include Kuiq::Control

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
end
