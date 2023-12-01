require "kuiq"
require "kuiq/model/dashboard_graph_presenter"

module Kuiq
  module View
    class DashboardGraph
      include Glimmer::LibUI::CustomControl

      option :job_manager
      
      attr_reader :presenter
      
      before_body do
        @presenter = Model::DashboardGraphPresenter.new(job_manager)
      end

      after_body do
        polling_interval = job_manager.polling_interval
        time_remaining = job_manager.polling_interval
        timer_interval = 1 # 1 second
        Glimmer::LibUI.timer(timer_interval) do
          presenter.record_stats
          if polling_interval != job_manager.polling_interval
            if job_manager.polling_interval < polling_interval
              time_remaining = job_manager.polling_interval
            else
              time_remaining += job_manager.polling_interval - polling_interval
            end
            polling_interval = job_manager.polling_interval
          end
          time_remaining -= timer_interval
          if time_remaining == 0
            job_manager.refresh
            body_root.queue_redraw_all
            time_remaining = job_manager.polling_interval
          end
        end
      end

      body {
        area {
          stretchy false

          rectangle(0, 0, WINDOW_WIDTH, GRAPH_HEIGHT) {
            fill 255, 255, 255
          }

          on_draw do
            job_status_graph(:failed)
            job_status_graph(:processed)
          end
        }
      }
      
      private
      
      def job_status_graph(job_status)
        last_point = nil
        presenter.report_points(job_status).each do |point|
          if last_point
            line(last_point.first, last_point.last, point.first, point.last) {
              stroke(*GRAPH_DASHBOARD_COLORS[job_status], thickness: 2)
            }
          end
          last_point = point
        end
      end
    end
  end
end
