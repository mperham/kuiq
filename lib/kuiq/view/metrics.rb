require "kuiq/view/stat_row"
require "kuiq/view/footer"

module Kuiq
  module View
    class Metrics
      include Glimmer::LibUI::CustomControl

      option :job_manager

      body {
        vertical_box {
          stat_row(group_title: t("Summary"), model: job_manager, attributes: Model::Job::STATUSES) {
            stretchy false
          }

          group(t("Metrics")) {
            margined false

            table {
              text_column(t("Name"))
              text_column(t("Success"))
              text_column(t("Failure"))
              text_column(t("TotalExecutionTime"))
              text_column(t("AvgExecutionTime"))

              cell_rows <= [job_manager, :metrics,
                column_attributes: {
                  t("Name") => :name,
                  t("Success") => :success,
                  t("Failure") => :failure,
                  t("TotalExecutionTime") => :tet,
                  t("AvgExecutionTime") => :aet
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
