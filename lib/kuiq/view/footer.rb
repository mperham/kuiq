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
          label(job_manager.current_time.strftime("%T UTC")) {
            stretchy false
          }
          label("docs") {
            stretchy false
          }
          label(job_manager.locale) {
            stretchy false
          }
        }
      }
    end
  end
end
