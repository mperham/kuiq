module Kuiq
  module View
    class ScheduledTable
      include Glimmer::LibUI::CustomControl

      option :job_manager

      body {
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
      }
    end
  end
end
