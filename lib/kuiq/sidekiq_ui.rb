require "sidekiq"
require "sidekiq/api"
require "glimmer-dsl-libui"

require "kuiq"
require "kuiq/model/job_manager"
require "kuiq/view/dashboard"
require "kuiq/view/retries"

module Kuiq
  class SidekiqUI
    include Glimmer::LibUI::Application
  
    before_body do
      @job_manager = Model::JobManager.new
    end
  
    after_body do
      # generate_jobs
    end
  
    body {
      window("Sidekiq UI", WINDOW_WIDTH, WINDOW_HEIGHT) {
        vertical_box {
          tab {
            tab_item("Dashboard") {
              dashboard(job_manager: @job_manager)
            }
            # TODO enable each tab when implemented (only implemented ones will be visible)
  #           tab_item("Busy") {
  #           }
  #           tab_item("Queues") {
  #           }
            tab_item("Retries") {
              retries(job_manager: @job_manager)
            }
  #           tab_item("Scheduled") {
  #           }
  #           tab_item("Dead") {
  #           }
  #           tab_item("Metrics") {
  #           }
          }
        }
      }
    }
  end
end
