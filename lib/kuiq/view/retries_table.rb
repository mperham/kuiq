module Kuiq
  module View
    class RetriesTable
      include Glimmer::LibUI::CustomControl

      option :job_manager

      body {
        table {
          text_column(t("NextRetry"))
          text_column(t("RetryCount"))
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
