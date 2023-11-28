require "kuiq/view/global_stats"
require "kuiq/view/busy_stats"
require "kuiq/view/footer"

module Kuiq
  module View
    class Busy
      include Glimmer::LibUI::CustomControl

      option :job_manager

      body {
        vertical_box {
          global_stats(group_title: t("Summary"), model: job_manager, attributes: Model::Job::STATUSES) {
            stretchy false
          }

          busy_stats(group_title: t("Status"), model: job_manager, attributes: %i[process_size total_concurrency busy utilization total_rss])

          group(t("Processes")) {
            margined false
            table {
              text_column(t("Name"))
              text_column(t("Started"))
              text_column(t("RSS"))
              text_column(t("Threads"))
              text_column(t("Busy"))

              # cell_rows job_manager.process_set.lazy
              cell_rows <=> [job_manager.process_set, :lazy, column_attributes: {
                t("Name") => :identity,
                t("Started") => :started_at,
                t("RSS") => :rss,
                t("Threads") => :concurrency,
                t("Busy") => :busy
              }]
            }
          }

          group(t("Jobs")) {
            margined false
            table {
              text_column(t("Process"))
              text_column(t("TID"))
              text_column(t("JID"))
              text_column(t("Queue"))
              text_column(t("Job"))
              text_column(t("Arguments"))
              text_column(t("Started"))

              # cell_rows job_manager.process_set.lazy
              cell_rows <=> [job_manager.work_set, :lazy, column_attributes: {
                t("Name") => :identity,
                t("Started") => :started_at,
                t("RSS") => :rss,
                t("Threads") => :concurrency,
                t("Busy") => :busy
              }]
            }
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
