module Kuiq
  module View
    class GraphicalLabel
      include Kuiq::Control

      option :label_text
      option :font_properties
      option :width, default: nil
      
      before_body do
        self.width ||= estimated_width_of_label_text
      end

      body {
        area {
          text(0, 0, width) {
            string(label_text) {
              font font_properties
            }
          }
        }
      }
      
      def estimated_width_of_label_text
        font_size = font_properties[:size] || 16
        estimated_font_width = 0.6 * font_size
        label_text.chars.size * estimated_font_width
      end
    end
  end
end
