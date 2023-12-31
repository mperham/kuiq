require "glimmer/view/line_graph"

require "kuiq"
require "kuiq/model/dashboard_graph_presenter"

module Kuiq
  module View
    class DashboardGraph
      include Glimmer::LibUI::CustomControl

      option :job_manager

      attr_reader :presenter

      before_body do
        @presenter = Model::DashboardGraphPresenter.new(job_manager, graph_width, graph_height)
        @points = {}
        @multi_day_points = {}
        @multi_day_selection_point = {}
      end

      after_body do
        body_root.window_proxy.content {
          on_content_size_changed do
            @live_poll_line_graph.width = @presenter.graph_width = graph_width
            @live_poll_line_graph.height = @presenter.graph_height = graph_height
            
            @history_line_graphs.values.each do |history_line_graph|
              history_line_graph.width = @presenter.graph_width
              history_line_graph.height = @presenter.graph_height
            end
          end
        }
        polling_interval = job_manager.polling_interval
        time_remaining = job_manager.polling_interval
        timer_interval = 1 # 1 second
        Glimmer::LibUI.timer(timer_interval) do
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
            presenter.record_stats
            job_manager.refresh
            @live_poll_line_graph.lines = report_graph_lines
            time_remaining = job_manager.polling_interval
          end
        end
      end

      body {
        tab {
          tab_item(t("LivePoll")) {
            @live_poll_line_graph = line_graph(
              width: @presenter.graph_width,
              height: @presenter.graph_height,
              lines: report_graph_lines,
              display_attributes_on_hover: true,
              graph_point_radius: 3,
              graph_selected_point_radius: 4,
              graph_fill_selected_point: :line_stroke,
            )
          }
          
          tab_item(t('OneWeek')) {
            history_line_graph(day_count: 7)
          }
          
          tab_item(t('OneMonth')) {
            history_line_graph(day_count: 30)
          }
          
          tab_item(t('ThreeMonths')) {
            history_line_graph(day_count: 90)
          }
          
          tab_item(t('SixMonths')) {
            history_line_graph(day_count: 180)
          }
          
        }
      }

      private
      
      def graph_width
        current_window_width = body_root&.window_proxy&.content_size&.first || WINDOW_WIDTH
        current_window_width - 24
      end
      
      def graph_height
        current_window_height = body_root&.window_proxy&.content_size&.last || WINDOW_HEIGHT
        current_window_height - 395
      end
      
      def report_graph_lines
        Model::DashboardGraphPresenter::JOB_STATUSES.map do |job_status|
          {
            name: t(job_status.capitalize),
            stroke: [*GRAPH_DASHBOARD_COLORS[job_status], thickness: 2],
          }.merge(presenter.report_stats(job_status))
        end
      end
      
      def history_line_graph(day_count: 30)
        @history_line_graphs ||= {}
        @history_line_graphs[day_count] = line_graph(
          width: @presenter.graph_width,
          height: @presenter.graph_height,
          lines: report_history_graph_lines(day_count: day_count),
          display_attributes_on_hover: true,
          graph_point_distance: :width_divided_by_point_count,
          graph_point_radius: 3,
          graph_selected_point_radius: 4,
          graph_fill_selected_point: :line_stroke,
        )
      end
      
      def report_history_graph_lines(day_count:)
        Model::DashboardGraphPresenter::JOB_STATUSES.map do |job_status|
          {
            name: t(job_status.capitalize),
            stroke: [*GRAPH_DASHBOARD_COLORS[job_status], thickness: 2],
          }.merge(presenter.report_history_stats(job_status, day_count))
        end
      end
      
    end
  end
end
