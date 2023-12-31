require "kuiq/view/dashboard_graph"
require "kuiq/view/stat_row"
require "kuiq/view/footer"

module Kuiq
  module View
    class Dashboard
      include Glimmer::LibUI::CustomControl

      option :job_manager

      body {
        vertical_box {
          stat_row(group_title: t("Summary"), model: job_manager, attributes: Model::Job::STATUSES) {
            stretchy false
          }

          group(t("Dashboard")) {
            margined false

            vertical_box {
              horizontal_box {
                stretchy false

                # filler
                label
                label

                vertical_box {
                  horizontal_box {
                    label("#{t("PollingInterval")}:") {
                      stretchy false
                    }

                    label {
                      text <= [job_manager, :polling_interval,
                        on_read: ->(val) { "#{val} sec" }]
                    }
                  }

                  slider(POLLING_INTERVAL_MIN, POLLING_INTERVAL_MAX) {
                    value <=> [job_manager, :polling_interval]
                  }
                }
              }

              dashboard_graph(job_manager: job_manager) {
                stretchy false
              }
            }
          }

          stat_row(group_title: "Redis", model: job_manager.redis_info, attributes: Model::JobManager::REDIS_PROPERTIES) {
            stretchy false
          }

          horizontal_separator {
            stretchy false
          }

          footer(job_manager: job_manager) {
            stretchy false
          }
        }
      }
    end
  end
end
