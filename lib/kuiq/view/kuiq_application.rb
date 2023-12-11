require "kuiq"
require "kuiq/i18n"
require "kuiq/ext/kernel"
require "kuiq/model/job_manager"
require "kuiq/view/dashboard"
require "kuiq/view/busy"
require "kuiq/view/retries"
require "kuiq/view/scheduled"
require "kuiq/view/morgue"
require "kuiq/view/queues"
require "kuiq/view/metrics"

module Kuiq
  class GUI
    include Glimmer::LibUI::Application

    before_body do
      @job_manager = Model::JobManager.new
    end

    body {
      window("Kuiq - Sidekiq UI", WINDOW_WIDTH, WINDOW_HEIGHT) {
        vertical_box {
          tab {
            tab_item(t("Dashboard")) {
              dashboard(job_manager: @job_manager)
            }
            # TODO enable each tab when implemented (only implemented ones will be visible)
            tab_item("Busy") {
              busy(job_manager: @job_manager)
            }
            tab_item("Queues") {
              queues(job_manager: @job_manager)
            }
            tab_item(t("Retries")) {
              retries(job_manager: @job_manager)
            }
            tab_item(t("Scheduled")) {
              scheduled(job_manager: @job_manager)
            }
            tab_item(t("Dead")) {
              morgue(job_manager: @job_manager)
            }
            tab_item("Metrics") {
              metrics(job_manager: @job_manager)
            }
          }
        }
      }
    }
  end
end
