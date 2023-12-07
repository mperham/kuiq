require "kuiq"
require "kuiq/model/dashboard_graph_presenter"

module Kuiq
  module View
    class DashboardGraph
      include Glimmer::LibUI::CustomControl

      option :job_manager

      attr_reader :presenter

      before_body do
        @presenter = Model::DashboardGraphPresenter.new(job_manager, graph_width)
        @points = {}
        @multi_day_points = {}
        @multi_day_selection_point = {}
      end

      after_body do
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
            @live_graph.queue_redraw_all
            time_remaining = job_manager.polling_interval
          end
        end
      end

      body {
        tab {
          tab_item(t("LivePoll")) {
            @live_graph = area {
              on_draw do
                @presenter.graph_width = graph_width
                graph_background
                grid_lines
                job_status_graph(:failed)
                job_status_graph(:processed)
                selection_stats
              end

              on_mouse_moved do |event|
                @selection_point = {x: event[:x], y: event[:y]}
                @live_graph.queue_redraw_all
              end

              on_mouse_exited do |outside|
                @selection_point = nil
                @live_graph.queue_redraw_all
              end
            }
          }
          
          tab_item(t('OneWeek')) {
            multi_day_graph_area(day_count: 7)
          }
          
          tab_item(t('OneMonth')) {
            multi_day_graph_area(day_count: 30)
          }
          
          tab_item(t('ThreeMonths')) {
            multi_day_graph_area(day_count: 90)
          }
          
          tab_item(t('SixMonths')) {
            multi_day_graph_area(day_count: 180)
          }
          
        }
      }

      private
      
      def graph_background
        rectangle(0, 0, graph_width, GRAPH_HEIGHT + GRAPH_STATUS_HEIGHT) {
          fill 255, 255, 255
        }
      end
      
      def graph_width
        current_window_width = body_root&.window_proxy&.content_size&.first || WINDOW_WIDTH
        current_window_width - 15
      end
      
      def grid_lines
        line(GRAPH_PADDING_WIDTH, GRAPH_PADDING_HEIGHT, GRAPH_PADDING_WIDTH, GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT) {
          stroke GRAPH_DASHBOARD_COLORS[:grid]
        }
        line(GRAPH_PADDING_WIDTH, GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT, graph_width - GRAPH_PADDING_WIDTH, GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT) {
          stroke GRAPH_DASHBOARD_COLORS[:grid]
        }
        grid_marker_points = presenter.grid_marker_points
        grid_marker_points.each_with_index do |marker_point, index|
          grid_marker_number_value = grid_marker_points.size - index
          grid_marker_number = grid_marker_number_value.to_s
          thick = index != grid_marker_points.size - 1
          mod_value = (2 * ((grid_marker_points.size / 30) + 1))
          comparison_value = (mod_value > 2) ? 0 : 1
          if mod_value > 2
            if grid_marker_number_value % mod_value == comparison_value
              line(marker_point[:x], marker_point[:y], marker_point[:x] + 4, marker_point[:y]) {
                stroke *GRAPH_DASHBOARD_COLORS[:marker], thickness: (thick ? 2 : 1)
              }
            end
          else
            line(marker_point[:x], marker_point[:y], marker_point[:x] + 4, marker_point[:y]) {
              stroke *GRAPH_DASHBOARD_COLORS[:marker], thickness: (thick ? 2 : 1)
            }
          end
          if grid_marker_number_value % mod_value == comparison_value && grid_marker_number_value != grid_marker_points.size
            line(marker_point[:x], marker_point[:y], marker_point[:x] + graph_width - GRAPH_PADDING_WIDTH, marker_point[:y]) {
              stroke *GRAPH_DASHBOARD_COLORS[:marker_dotted_line], thickness: 1, dashes: [1, 1]
            }
          end
          if grid_marker_number_value % mod_value == comparison_value
            text(marker_point[:x] + 4 + 3, marker_point[:y] - 6, 20) {
              string(grid_marker_number) {
                font family: "Arial", size: 11
                color GRAPH_DASHBOARD_COLORS[:marker_text]
              }
            }
          end
        end
      end

      def job_status_graph(job_status)
        last_point = nil
        @points[job_status] = presenter.report_points(job_status)
        @points[job_status].each do |point|
          if last_point
            line(last_point[:x], last_point[:y], point[:x], point[:y]) {
              stroke *GRAPH_DASHBOARD_COLORS[job_status], thickness: 2
            }
          end
          last_point = point
        end
      end

      def selection_stats
        require "bigdecimal"
        require "perfect_shape/point"
        if @selection_point
          x = @selection_point[:x]
          closest_processed_point = @points[:processed].min_by { |point| (point[:x] - x).abs }
          closest_failed_point = @points[:failed][@points[:processed].index(closest_processed_point)] if closest_processed_point
          closest_x = closest_processed_point&.[](:x)
          closest_x_distance = PerfectShape::Point.point_distance(x.to_f, 0, closest_x.to_f, 0)
          if closest_x_distance < GRAPH_POINT_DISTANCE
            line(closest_x, GRAPH_PADDING_HEIGHT, closest_x, GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT) {
              stroke *GRAPH_DASHBOARD_COLORS[:selection_stats]
            }
            circle(closest_failed_point[:x], closest_failed_point[:y], 4) {
              fill *GRAPH_DASHBOARD_COLORS[:failed]
            }
            circle(closest_failed_point[:x], closest_failed_point[:y], 2) {
              fill :white
            }
            circle(closest_processed_point[:x], closest_processed_point[:y], 4) {
              fill *GRAPH_DASHBOARD_COLORS[:processed]
            }
            circle(closest_processed_point[:x], closest_processed_point[:y], 2) {
              fill :white
            }
            text_label_x = (graph_width / 2.0)
            text_label_y = GRAPH_HEIGHT + GRAPH_PADDING_HEIGHT
            text_label_width = 220
            font_height = 14
            text(text_label_x, text_label_y, text_label_width) {
              string(closest_processed_point[:time]) {
                font family: "Arial", size: font_height
                color GRAPH_DASHBOARD_COLORS[:marker_text]
              }
            }
            square(text_label_x + text_label_width, text_label_y + 2, font_height - 2) {
              fill GRAPH_DASHBOARD_COLORS[:failed]
            }
            text(text_label_x + text_label_width + font_height + 2, text_label_y, text_label_width / 3.0) {
              string("#{t("Failed")}: #{closest_failed_point[:failed]}") {
                font family: "Arial", size: 14
                color GRAPH_DASHBOARD_COLORS[:marker_text]
              }
            }
            square(text_label_x + (4.0 / 3.0) * text_label_width + font_height + 2, text_label_y + 2, font_height - 2) {
              fill GRAPH_DASHBOARD_COLORS[:processed]
            }
            text(text_label_x + (4.0 / 3.0) * text_label_width + 2 * font_height + 4, text_label_y, text_label_width) {
              string("#{t("Processed")}: #{closest_processed_point[:processed]}") {
                font family: "Arial", size: 14
                color GRAPH_DASHBOARD_COLORS[:marker_text]
              }
            }
          end
        end
      end
      
      def multi_day_graph_area(day_count: 30)
        area { |graph_area|
          on_draw do
            multi_day_graph(day_count)
          end

          on_mouse_moved do |event|
            @multi_day_selection_point[day_count] = {x: event[:x], y: event[:y]}
            graph_area.queue_redraw_all
          end

          on_mouse_exited do |outside|
            @multi_day_selection_point[day_count] = nil
            graph_area.queue_redraw_all
          end
        }
      end
      
      def multi_day_graph(day_count)
        @presenter.graph_width = graph_width
        graph_background
        multi_day_grid_lines(day_count)
        multi_day_job_status_graph(day_count, :failed)
        multi_day_job_status_graph(day_count, :processed)
        multi_day_periodic_lines(day_count)
        multi_day_selection_stats(day_count)
      end
      
      def multi_day_grid_lines(day_count)
        line(GRAPH_PADDING_WIDTH, GRAPH_PADDING_HEIGHT, GRAPH_PADDING_WIDTH, GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT) {
          stroke GRAPH_DASHBOARD_COLORS[:grid]
        }
        line(GRAPH_PADDING_WIDTH, GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT, graph_width - GRAPH_PADDING_WIDTH, GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT) {
          stroke GRAPH_DASHBOARD_COLORS[:grid]
        }
        grid_marker_points = presenter.multi_day_grid_marker_points(day_count)
        grid_marker_points.each_with_index do |marker_point, index|
          grid_marker_number_value = (grid_marker_points.size - index).to_i
          grid_marker_number = (grid_marker_number_value >= 1000) ? "#{grid_marker_number_value / 1000}K" : grid_marker_number.to_s
          thick = index != grid_marker_points.size - 1
          mod_value = (2 * ((grid_marker_points.size / 30) + 1))
          comparison_value = (mod_value > 2) ? 0 : 1
          if mod_value > 2
            if grid_marker_number_value % mod_value == comparison_value
              line(marker_point[:x], marker_point[:y], marker_point[:x] + 4, marker_point[:y]) {
                stroke *GRAPH_DASHBOARD_COLORS[:marker], thickness: (thick ? 2 : 1)
              }
            end
          else
            line(marker_point[:x], marker_point[:y], marker_point[:x] + 4, marker_point[:y]) {
              stroke *GRAPH_DASHBOARD_COLORS[:marker], thickness: (thick ? 2 : 1)
            }
          end
          if grid_marker_number_value % mod_value == comparison_value && grid_marker_number_value != grid_marker_points.size
            line(marker_point[:x], marker_point[:y], marker_point[:x] + graph_width - GRAPH_PADDING_WIDTH, marker_point[:y]) {
              stroke *GRAPH_DASHBOARD_COLORS[:marker_dotted_line], thickness: 1, dashes: [1, 1]
            }
          end
          if grid_marker_number_value % mod_value == comparison_value
            text(marker_point[:x] + 4 + 3, marker_point[:y] - 6, 30) {
              string(grid_marker_number) {
                font family: "Arial", size: 11
                color GRAPH_DASHBOARD_COLORS[:marker_text]
              }
            }
          end
        end
      end
      
      def multi_day_job_status_graph(day_count, job_status)
        last_point = nil
        @multi_day_points[day_count] ||= {}
        @multi_day_points[day_count][job_status] = presenter.multi_day_report_points(day_count, job_status)
        @multi_day_points[day_count][job_status].each do |point|
          if last_point
            line(last_point[:x], last_point[:y], point[:x], point[:y]) {
              stroke *GRAPH_DASHBOARD_COLORS[job_status], thickness: 2
            }
          end
          last_point = point
        end
      end
      
      def multi_day_selection_stats(day_count)
        require 'bigdecimal'
        require 'perfect_shape/point'
        if @multi_day_selection_point[day_count]
          x = @multi_day_selection_point[day_count][:x]
          closest_processed_point = @multi_day_points[day_count][:processed].min_by {|point| (point[:x] - x).abs }
          closest_failed_point = @multi_day_points[day_count][:failed][@multi_day_points[day_count][:processed].index(closest_processed_point)] if closest_processed_point
          closest_x = closest_processed_point&.[](:x)
          closest_x_distance = PerfectShape::Point.point_distance(x.to_f, 0, closest_x.to_f, 0)
          if closest_x_distance < presenter.multi_day_graph_point_distance(day_count)
            line(closest_x, GRAPH_PADDING_HEIGHT, closest_x, GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT) {
              stroke *GRAPH_DASHBOARD_COLORS[:selection_stats]
            }
            circle(closest_failed_point[:x], closest_failed_point[:y], 4) {
              fill *GRAPH_DASHBOARD_COLORS[:failed]
            }
            circle(closest_failed_point[:x], closest_failed_point[:y], 2) {
              fill :white
            }
            circle(closest_processed_point[:x], closest_processed_point[:y], 4) {
              fill *GRAPH_DASHBOARD_COLORS[:processed]
            }
            circle(closest_processed_point[:x], closest_processed_point[:y], 2) {
              fill :white
            }
            text_label_x = (graph_width / 2.0)
            text_label_y = GRAPH_HEIGHT + GRAPH_PADDING_HEIGHT
            text_label_width = 130
            font_height = 14
            text(text_label_x, text_label_y, text_label_width) {
              string(closest_processed_point[:time]) {
                font family: "Arial", size: font_height
                color GRAPH_DASHBOARD_COLORS[:marker_text]
              }
            }
            square(text_label_x + text_label_width, text_label_y + 2, font_height - 2) {
              fill GRAPH_DASHBOARD_COLORS[:failed]
            }
            text(text_label_x + text_label_width + font_height + 2, text_label_y, text_label_width) {
              string("#{t("Failed")}: #{closest_failed_point[:failed]}") {
                font family: "Arial", size: 14
                color GRAPH_DASHBOARD_COLORS[:marker_text]
              }
            }
            square(text_label_x + 2 * text_label_width + font_height + 2, text_label_y + 2, font_height - 2) {
              fill GRAPH_DASHBOARD_COLORS[:processed]
            }
            text(text_label_x + 2 * text_label_width + 2 * font_height + 4, text_label_y, text_label_width) {
              string("#{t("Processed")}: #{closest_processed_point[:processed]}") {
                font family: "Arial", size: 14
                color GRAPH_DASHBOARD_COLORS[:marker_text]
              }
            }
          end
        end
      end
      
      def multi_day_periodic_lines(day_count)
        case day_count
        when ..7
          @multi_day_points[day_count][:processed].each do |point|
            line(point[:x], GRAPH_PADDING_HEIGHT, point[:x], GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT) {
              stroke *GRAPH_DASHBOARD_COLORS[:periodic_line], thickness: 1, dashes: [1, 1]
            }
            day = point[:raw_time].strftime("%e")
            font_size = 14
            text(point[:x], GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT - font_size*1.4, font_size) {
              string(day) {
                font family: "Arial", size: font_size
                color GRAPH_DASHBOARD_COLORS[:failed]
              }
            }
          end
        when ..30
          @multi_day_points[day_count][:processed].each_with_index do |point, index|
            day_number = index + 1
            if day_number % 7 == 0
              line(point[:x], GRAPH_PADDING_HEIGHT, point[:x], GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT) {
                stroke *GRAPH_DASHBOARD_COLORS[:periodic_line], thickness: 1, dashes: [1, 1]
              }
              date = point[:raw_time].strftime("%b %e")
              font_size = 14
              text(point[:x] + 4, GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT - font_size*1.4, font_size*6) {
                string(date) {
                  font family: "Arial", size: font_size
                  color GRAPH_DASHBOARD_COLORS[:failed]
                }
              }
            end
          end
        else
          @multi_day_points[day_count][:processed].each do |point|
            if point[:raw_time].strftime("%d") == "01"
              line(point[:x], GRAPH_PADDING_HEIGHT, point[:x], GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT) {
                stroke *GRAPH_DASHBOARD_COLORS[:periodic_line], thickness: 1, dashes: [1, 1]
              }
              date = point[:raw_time].strftime("%b")
              font_size = 14
              text(point[:x] + 4, GRAPH_HEIGHT - GRAPH_PADDING_HEIGHT - font_size*1.4, font_size*6) {
                string(date) {
                  font family: "Arial", size: font_size
                  color GRAPH_DASHBOARD_COLORS[:failed]
                }
              }
            end
          end
        end
      end
      
    end
  end
end
