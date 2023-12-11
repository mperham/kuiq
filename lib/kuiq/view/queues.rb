require "kuiq/view/stat_row"
require "kuiq/view/footer"

module Kuiq
  module View
    class Queues
      include Glimmer::LibUI::CustomControl

      option :job_manager

      body {
        vertical_box {
          stat_row(group_title: t("Summary"), model: job_manager, attributes: Model::Job::STATUSES) {
            stretchy false
          }

          group(t("Queues")) {
            margined false

            table {
              text_column(t("Name"))
              text_column(t("Size"))
              text_column(t("Latency"))
              text_column(t("Actions"))

              cell_rows <= [job_manager, :queues,
                column_attributes: {
                  t("Name") => :name,
                  t("Size") => :size,
                  t("Latency") => :latency,
                  t("Actions") => :actions
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
