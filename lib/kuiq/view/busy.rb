require "kuiq/view/stat_row"
require "kuiq/view/footer"

module Kuiq
  module View
    class Busy
      include Glimmer::LibUI::CustomControl

      option :job_manager

      body {
        vertical_box {
          stat_row(group_title: t("Summary"), model: job_manager, attributes: Model::Job::STATUSES) {
            stretchy false
          }

          stat_row(group_title: t("Status"), model: job_manager, attributes: Model::JobManager::BUSY_PROPERTIES) {
            stretchy false
          }

          table_toolbar(job_manager: job_manager, include_filter: false) {
            stretchy false
          }

          group(t("Processes")) {
            margined false

            table {
              text_column(t("Name"))
              text_column(t("Started"))
              text_column(t("RSS"))
              text_column(t("Threads"))
              text_column(t("Busy"))
              text_column(t("Labels"))
              text_column(t("Queues"))

              cell_rows <= [job_manager, :processes,
                column_attributes: {
                  t("Name") => :identity,
                  t("Started") => :started_at,
                  t("RSS") => :rss,
                  t("Threads") => :concurrency,
                  t("Busy") => :busy,
                  t("Labels") => :labels,
                  t("Queues") => :queues,
                }]
            }
          }
          
          horizontal_box {
            stretchy false
            
            # filler
            label
            
            label("#{t("Queue")}:") {
              stretchy false
            }
          
            combobox {
              stretchy false
              
              items [''] + job_manager.queues.map(&:name)
              selected_item <=> [job_manager, :work_queue_filter]
            }
          }

          group(t("Jobs")) {
            margined false

            table {
              text_column(t("Process"))
              text_column(t("Started"))
              text_column(t("TID"))
              text_column(t("JID"))
              text_column(t("Queue"))
              text_column(t("Job"))
              text_column(t("Arguments"))

              cell_rows <= [job_manager, :works,
                column_attributes: {
                  t("Process") => :process,
                  t("Started") => :started_at,
                  t("TID") => :thread,
                  t("JID") => :jid,
                  t("Queue") => :queue,
                  t("Job") => :job_class,
                  t("Arguments") => :args,
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
