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

          cell_rows job_manager.scheduled_jobs
        }
      }
    end
  end
end
