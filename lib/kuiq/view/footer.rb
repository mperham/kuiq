module Kuiq
  module View
    class Footer
      include Glimmer::LibUI::CustomControl

      option :job_manager

      body {
        horizontal_box {
          label("Sidekiq v#{Sidekiq::VERSION}") {
            stretchy false
          }
          label(job_manager.redis_url) {
            stretchy false
          }
          label {
            stretchy false
            
            text <= [job_manager, :current_time, on_read: -> (val) { val.strftime("%T UTC") }]
          }
          label(I18n.current_locale) {
            stretchy false
          }
        }
      }
    end
  end
end
