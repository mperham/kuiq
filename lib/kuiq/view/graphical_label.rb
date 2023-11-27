module Kuiq
  module View
    class GraphicalLabel
      include Kuiq::Control

      option :label_text
      option :width
      option :font_properties

      body {
        area {
          text(0, 0, width) {
            string(label_text) {
              font font_properties
            }
          }
        }
      }
    end
  end
end
