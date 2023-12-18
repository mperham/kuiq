require "kuiq/view/stat_row"
require "kuiq/view/table_toolbar"
require "kuiq/view/footer"

module Kuiq
  module View
    class Scheduled
      include Glimmer::LibUI::CustomControl

      option :job_manager

      body {
        vertical_box {
          stat_row(group_title: t("Summary"), model: job_manager, attributes: Model::Job::STATUSES) {
            stretchy false
          }
          
          table_toolbar(job_manager: job_manager, filter_name: "schedule") {
            stretchy false
          }

          table {
            text_column(t("When"))
            text_column(t("Queue"))
            text_column(t("Job"))
            text_column(t("Arguments"))

            cell_rows <= [job_manager, :scheduled_jobs,
              column_attributes: {
                t("When") => :when,
                t("Queue") => :queue,
                t("Job") => :job,
                t("Arguments") => :arguments
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
