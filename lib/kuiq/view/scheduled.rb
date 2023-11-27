require "kuiq/view/global_stats"
require "kuiq/view/scheduled_table"
require "kuiq/view/footer"

module Kuiq
  module View
    class Scheduled
      include Kuiq::Control

      option :job_manager

      body {
        vertical_box {
          global_stats(model: job_manager, attributes: Model::Job::STATUSES) {
            stretchy false
          }

          scheduled_table(job_manager: job_manager)

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
