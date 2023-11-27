module Kuiq
  module View
    class RetriesTable
      include Kuiq::Control

      option :job_manager

      body {
        table {
          text_column(t("Next Retry"))
          text_column(t("Retry Count"))
          text_column(t("Queue"))
          text_column(t("Job"))
          text_column(t("Arguments"))
          text_column(t("Error"))

          cell_rows job_manager.retried_jobs
        }
      }
    end
  end
end
