require "kuiq/view/stat_row"
require "kuiq/view/table_toolbar"
require "kuiq/view/footer"

module Kuiq
  module View
    class Morgue
      include Glimmer::LibUI::CustomControl

      option :job_manager

      body {
        vertical_box {
          stat_row(group_title: t("Summary"), model: job_manager, attributes: Model::Job::STATUSES) {
            stretchy false
          }
          
          table_toolbar(job_manager: job_manager, filter_name: "dead") {
            stretchy false
          }

          table {
            text_column(t("LastRetry"))
            text_column(t("Queue"))
            text_column(t("Job"))
            text_column(t("Arguments"))
            text_column(t("Error"))

            cell_rows <= [job_manager, :dead_jobs,
              column_attributes: {
                t("LastRetry") => :last_retry,
                t("Queue") => :queue,
                t("Job") => :job,
                t("Arguments") => :arguments,
                t("Error") => :error
              }]
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
