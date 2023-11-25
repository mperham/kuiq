module View
  class StatusBar
    include Glimmer::LibUI::CustomControl
  
    option :job_manager
  
    before_body do
      @text_font_family = (OS.mac? ? "Helvetica" : "Arial")
      @text_font_size = (OS.mac? ? 14 : 11)
      @text_font = {family: @text_font_family, size: @text_font_size}
      @text_color = :grey
      @background_color = :black
    end
  
    body {
      area {
        rectangle(0, 0, 800, 30) {
          fill @background_color
        }
  
        text(20, 5, 100) {
          string("Sidekiq v#{Sidekiq::VERSION}") {
            font @text_font
            color @text_color
          }
        }
  
        text(120, 5, 160) {
          string(job_manager.redis_url) {
            font @text_font
            color @text_color
          }
        }
  
        text(280, 5, 100) {
          string(job_manager.current_time.strftime("%T UTC")) {
            font @text_font
            color @text_color
          }
        }
  
        text(380, 5, 100) {
          string("docs") {
            font @text_font
            color :red
          }
  
          # on_mouse_up do
          #   system "open #{job_manager.docs_url}"
          # end
        }
  
        text(480, 5, 100) {
          string(job_manager.locale) {
            font @text_font
            color :red
          }
  
          # on_mouse_up do
          #   system "open #{job_manager.locale_url}"
          # end
        }
      }
    }
  end
end
