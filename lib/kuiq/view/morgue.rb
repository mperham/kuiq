require "kuiq/view/global_stats"
require "kuiq/view/footer"

module Kuiq
  module View
    class Morgue
      include Glimmer::LibUI::CustomControl

      option :job_manager

      body {
        vertical_box {
          global_stats(group_title: t("Summary"), model: job_manager, attributes: Model::Job::STATUSES) {
            stretchy false
          }

          table {
            text_column(t("When"))
            text_column(t("Queue"))
            text_column(t("Job"))
            text_column(t("Arguments"))
            text_column(t("Error"))

            cell_rows <= [job_manager, :dead_jobs,
                           column_attributes: {
                             t("When") => :when,
                             t("Queue") => :queue,
                             t("Job") => :job,
                             t("Arguments") => :arguments,
                             t("Error") => :error,
                           }
                         ]
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
