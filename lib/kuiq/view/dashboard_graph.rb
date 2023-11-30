require "kuiq"

module Kuiq
  module View
    class DashboardGraph
      include Glimmer::LibUI::CustomControl

      option :job_manager

      after_body do
        polling_interval = job_manager.polling_interval
        time_remaining = job_manager.polling_interval
        timer_interval = 1 # 1 second
        Glimmer::LibUI.timer(timer_interval) do
          job_manager.record_stats
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
            last_point = nil
            job_manager.report_points.each do |point|
              circle(point.first, point.last, 3) {
                fill *GRAPH_DASHBOARD_COLOR
              }
              if last_point
                line(last_point.first, last_point.last, point.first, point.last) {
                  stroke *GRAPH_DASHBOARD_COLOR, thickness: 2
                }
              end
              last_point = point
            end
          end
        }
      }
    end
  end
end
