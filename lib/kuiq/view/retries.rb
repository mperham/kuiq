require "kuiq/view/global_stats"
require "kuiq/view/retries_table"
require "kuiq/view/footer"

module Kuiq
  module View
    class Retries
      include Glimmer::LibUI::CustomControl

      option :job_manager

      body {
        vertical_box {
          global_stats(model: job_manager, attributes: Model::Job::STATUSES) {
            stretchy false
          }

          retries_table(job_manager: job_manager)

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
