require "sidekiq"
require "sidekiq/api"
require "glimmer-dsl-libui"

require "kuiq/models"
require "kuiq/components"

class AdminUI
  include Glimmer::LibUI::Application

  before_body do
    @job_manager = JobManager.new
  end

  after_body do
    # generate_jobs
  end

  body {
    window("Sidekiq UI", 800, 450) {
      vertical_box {
        tab {
          tab_item("Dashboard") {
            dashboard(job_manager: @job_manager)
          }
          tab_item("Busy") {
          }
          tab_item("Queues") {
          }
          tab_item("Retries") {
          }
          tab_item("Scheduled") {
          }
          tab_item("Dead") {
          }
          tab_item("Metrics") {
          }
        }
      }
    }
  }
end
