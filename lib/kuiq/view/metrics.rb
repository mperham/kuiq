require "kuiq/model/metrics_graph_presenter"

require "kuiq/view/stat_row"
require "kuiq/view/footer"

module Kuiq
  module View
    class Metrics
      include Glimmer::LibUI::CustomControl

      option :job_manager
      
      before_body do
        @presenter = Model::MetricsGraphPresenter.new(job_manager, graph_width, graph_height)
      end
      
      after_body do
        body_root.window_proxy.content {
          on_content_size_changed do
            @metrics_line_graph.width = @presenter.graph_width = graph_width
            @metrics_line_graph.height = @presenter.graph_height = graph_height
          end
        }
        
        job_manager.metrics.each do |class_metric|
          observe(class_metric, 'swatch_name_color[0]') do
            @metrics_line_graph.lines = @presenter.report_graph_lines
          end
        end
      end

      body {
        vertical_box {
          stat_row(group_title: t("Summary"), model: job_manager, attributes: Model::Job::STATUSES) {
            stretchy false
          }

          group(t("Metrics")) {
            margined false
            
            vertical_box {
              @metrics_line_graph = line_graph(
                width: @presenter.graph_width,
                height: @presenter.graph_height,
                lines: @presenter.report_graph_lines,
                graph_point_distance: :width_divided_by_point_count,
                graph_point_radius: 3,
                graph_selected_point_radius: 4,
                graph_fill_selected_point: :line_stroke,
              )
  
              table {
                checkbox_text_color_column(t("Name")) {
                  editable_checkbox true
                }
                text_column(t("Success"))
                text_column(t("Failure"))
                text_column(t("TotalExecutionTime"))
                text_column(t("AvgExecutionTime"))
  
                cell_rows <= [job_manager, :metrics,
                  column_attributes: {
                    t("Name") => :swatch_name_color,
                    t("Success") => :success,
                    t("Failure") => :failure,
                    t("TotalExecutionTime") => :tet,
                    t("AvgExecutionTime") => :aet,
                  }]
              }
            }
            
          }

          horizontal_separator {
            stretchy false
          }

          footer(job_manager: job_manager) {
            stretchy false
          }
        }
      }
      
      def graph_width
        current_window_width = body_root&.window_proxy&.content_size&.first || WINDOW_WIDTH
        current_window_width - 24
      end
      
      def graph_height
        current_window_height = body_root&.window_proxy&.content_size&.last || WINDOW_HEIGHT
        (current_window_height - 160)/2.0 - 5
      end
      
    end
  end
end
