module Kuiq
  module View
    # General-Purpose Line Graph Custom Control
    # TODO extract into a Ruby gem once implementation has been completed
    class LineGraph
      include Glimmer::LibUI::CustomControl
      
      DEFAULT_GRAPH_PADDING_WIDTH = 5.0
      DEFAULT_GRAPH_PADDING_HEIGHT = 5.0
      DEFAULT_GRAPH_GRID_MARKER_PADDING_WIDTH = 30.0
      DEFAULT_GRAPH_POINT_DISTANCE = 15.0
      
      DEFAULT_GRAPH_STROKE_GRID = [185, 184, 185]
      DEFAULT_GRAPH_STROKE_MARKER = [185, 184, 185]
      DEFAULT_GRAPH_STROKE_MARKER_LINE = [217, 217, 217, thickness: 1, dashes: [1, 1]]
      DEFAULT_GRAPH_STROKE_PERIODIC_LINE = [121, 121, 121, thickness: 1, dashes: [1, 1]]
      DEFAULT_GRAPH_STROKE_HOVER_LINE = [133, 133, 133]
      
      DEFAULT_GRAPH_COLOR_MARKER_TEXT = [96, 96, 96]
      DEFAULT_GRAPH_COLOR_PERIOD_TEXT = [163, 40, 39]
      
      DEFAULT_GRAPH_FONT_MARKER_TEXT = {family: "Arial", size: 14}
      
      DEFAULT_GRAPH_STATUS_HEIGHT = 30.0
      
      DAY_IN_SECONDS = 60*60*24
  
      option :width, default: 600
      option :height, default: 200
      
      # Hash or Array of Hash's like:
      # {
      #   name: 'Attribute Name',
      #   stroke: [28, 34, 89, thickness: 3],
      #   x_value_start: Time.now,
      #   x_interval_in_seconds: 2,
      #   x_value_format: ->(time) {time.strftime('%s')},
      #   y_values: [...]
      # }
      option :lines, default: []
      
      option :graph_padding_width, default: DEFAULT_GRAPH_PADDING_WIDTH
      option :graph_padding_height, default: DEFAULT_GRAPH_PADDING_HEIGHT
      option :graph_grid_marker_padding_width, default: DEFAULT_GRAPH_GRID_MARKER_PADDING_WIDTH
      option :graph_point_distance, default: DEFAULT_GRAPH_POINT_DISTANCE
      
      option :graph_stroke_grid, default: DEFAULT_GRAPH_STROKE_GRID
      option :graph_stroke_marker, default: DEFAULT_GRAPH_STROKE_MARKER
      option :graph_stroke_marker_line, default: DEFAULT_GRAPH_STROKE_MARKER_LINE
      option :graph_stroke_periodic_line, default: DEFAULT_GRAPH_STROKE_PERIODIC_LINE
      option :graph_stroke_hover_line, default: DEFAULT_GRAPH_STROKE_HOVER_LINE
      
      option :graph_color_marker_text, default: DEFAULT_GRAPH_COLOR_MARKER_TEXT
      option :graph_color_period_text, default: DEFAULT_GRAPH_COLOR_PERIOD_TEXT
      
      option :graph_font_marker_text, default: DEFAULT_GRAPH_FONT_MARKER_TEXT
      
      option :graph_status_height, default: DEFAULT_GRAPH_STATUS_HEIGHT
      
      option :display_attributes_on_hover, default: false
      
      before_body do
        self.lines = [lines] if lines.is_a?(Hash)
      end
      
      after_body do
        observe(self, :lines) do
          clear_drawing_cache
          body_root.queue_redraw_all
        end
        observe(self, :width) do
          clear_drawing_cache
        end
        observe(self, :height) do
          clear_drawing_cache
        end
      end
  
      body {
        area { |graph_area|
          on_draw do
            calculate_dynamic_options
            graph_background
            grid_lines
            all_line_graphs
            periodic_lines
            hover_stats
          end

          on_mouse_moved do |event|
            @hover_point = {x: event[:x], y: event[:y]}
        
            if @hover_point && lines && lines[0] && @points && @points[lines[0]] && !@points[lines[0]].empty?
              x = @hover_point[:x]
              closest_point_index = @points[lines[0]].each_with_index.min_by { |point, index| (point[:x] - x).abs }[1]
              if closest_point_index != @closest_point_index
                @closest_point_index = closest_point_index
                graph_area.queue_redraw_all
              end
            end
          end

          on_mouse_exited do |outside|
            if !@hover_point.nil?
              @hover_point = nil
              @closest_point_index = nil
              graph_area.queue_redraw_all
            end
          end
        }
      }
      
      private
      
      def clear_drawing_cache
        @graph_point_distance_per_line = nil
        @y_value_max_for_all_lines = nil
        @grid_marker_points = nil
        @points = nil
      end
      
      def calculate_dynamic_options
        calculate_graph_point_distance_per_line
      end
      
      def calculate_graph_point_distance_per_line
        return unless graph_point_distance == :width_divided_by_point_count
        
        @graph_point_distance_per_line = lines.inject({}) do |hash, line|
          hash.merge(line => (width - 2.0*graph_padding_width - graph_grid_marker_padding_width) / (line[:y_values].size - 1).to_f)
        end
      end
      
      def graph_point_distance_for_line(line)
        @graph_point_distance_per_line&.[](line) || graph_point_distance
      end
      
      def graph_background
        rectangle(0, 0, width, height + (display_attributes_on_hover ? graph_status_height : 0)) {
          fill 255, 255, 255
        }
      end
  
      def grid_lines
        line(graph_padding_width, graph_padding_height, graph_padding_width, height - graph_padding_height) {
          stroke graph_stroke_grid
        }
        line(graph_padding_width, height - graph_padding_height, width - graph_padding_width, height - graph_padding_height) {
          stroke graph_stroke_grid
        }
        grid_marker_points.each_with_index do |marker_point, index|
          grid_marker_number_value = (grid_marker_points.size - index).to_i
          grid_marker_number = (grid_marker_number_value >= 1000) ? "#{grid_marker_number_value / 1000}K" : grid_marker_number_value.to_s
          graph_stroke_marker_value = Glimmer::LibUI.interpret_color(graph_stroke_marker)
          graph_stroke_marker_value[:thickness] = (index != grid_marker_points.size - 1 ? 2 : 1) if graph_stroke_marker_value[:thickness].nil?
          mod_value = (2 * ((grid_marker_points.size / max_marker_count) + 1))
          comparison_value = (mod_value > 2) ? 0 : 1
          if mod_value > 2
            if grid_marker_number_value % mod_value == comparison_value
              line(marker_point[:x], marker_point[:y], marker_point[:x] + 4, marker_point[:y]) {
                stroke graph_stroke_marker_value
              }
            end
          else
            line(marker_point[:x], marker_point[:y], marker_point[:x] + 4, marker_point[:y]) {
              stroke graph_stroke_marker_value
            }
          end
          if grid_marker_number_value % mod_value == comparison_value && grid_marker_number_value != grid_marker_points.size
            line(marker_point[:x], marker_point[:y], marker_point[:x] + width - graph_padding_width, marker_point[:y]) {
              stroke graph_stroke_marker_line
            }
          end
          if grid_marker_number_value % mod_value == comparison_value
            grid_marker_number_font = graph_font_marker_text.merge(size: 11)
            grid_marker_number_width = estimate_width_of_text(grid_marker_number, grid_marker_number_font)
            text(marker_point[:x] + 4 + 3, marker_point[:y] - 6, grid_marker_number_width) {
              string(grid_marker_number) {
                font grid_marker_number_font
                color graph_color_marker_text
              }
            }
          end
        end
      end
      
      def grid_marker_points
        if @grid_marker_points.nil?
          graph_max = [y_value_max_for_all_lines, 1].max
          current_graph_height = (height - graph_padding_height * 2)
          division_height = current_graph_height / graph_max
          @grid_marker_points = graph_max.to_i.times.map do |marker_index|
            x = graph_padding_width
            y = graph_padding_height + marker_index * division_height
            {x: x, y: y}
          end
        end
        @grid_marker_points
      end
      
      def max_marker_count
        [(0.15*height).to_i, 1].max
      end
      
      def all_line_graphs
        lines.each { |graph_line| single_line_graph(graph_line) }
      end

      def single_line_graph(graph_line)
        last_point = nil
        points = calculate_points(graph_line)
        points.each do |point|
          if last_point
            line(last_point[:x], last_point[:y], point[:x], point[:y]) {
              stroke graph_line[:stroke]
            }
          end
          last_point = point
        end
      end
      
      def calculate_points(graph_line)
        @points ||= {}
        if @points[graph_line].nil?
          y_values = graph_line[:y_values] || []
          y_values = y_values[0, max_visible_point_count(graph_line)]
          graph_max = [y_value_max_for_all_lines, 1].max
          points = y_values.each_with_index.map do |y_value, index|
            x = width - graph_padding_width - (index * graph_point_distance_for_line(graph_line))
            y = ((height - graph_padding_height) - y_value * ((height - graph_padding_height * 2) / graph_max))
            {x: x, y: y, index: index, y_value: y_value}
          end
          @points[graph_line] = translate_points(graph_line, points)
        end
        @points[graph_line]
      end
      
      def y_value_max_for_all_lines
        if @y_value_max_for_all_lines.nil?
          all_y_values = lines.map { |line| line[:y_values] }.reduce(:+)
          @y_value_max_for_all_lines = all_y_values.max.to_f
        end
        @y_value_max_for_all_lines
      end
      
      def translate_points(graph_line, points)
        max_job_count_before_translation = ((width / graph_point_distance_for_line(graph_line)).to_i + 1)
        x_translation = [(points.size - max_job_count_before_translation) * graph_point_distance_for_line(graph_line), 0].max
        if x_translation > 0
          points.each do |point|
            # need to check if point[:x] is present because if the user shrinks the window, we drop points
            point[:x] = point[:x] - x_translation if point[:x]
          end
        end
        points
      end
      
      def max_visible_point_count(graph_line) = (width / graph_point_distance_for_line(graph_line)).to_i + 1

      def periodic_lines
        return unless lines && lines[0] && lines[0][:x_interval_in_seconds] && lines[0][:x_interval_in_seconds] == DAY_IN_SECONDS
        day_count = lines[0][:y_values].size
        case day_count
        when ..7
          @points[lines[0]].each do |point|
            line(point[:x], graph_padding_height, point[:x], height - graph_padding_height) {
              stroke graph_stroke_periodic_line
            }
            day = calculated_x_value(point[:index]).strftime("%e")
            font_size = graph_font_marker_text[:size]
            text(point[:x], height - graph_padding_height - font_size*1.4, font_size*2) {
              string(day) {
                font graph_font_marker_text
                color graph_color_period_text
              }
            }
          end
        when ..30
          @points[lines[0]].each_with_index do |point, index|
            day_number = index + 1
            if day_number % 7 == 0
              line(point[:x], graph_padding_height, point[:x], height - graph_padding_height) {
                stroke graph_stroke_periodic_line
              }
              date = calculated_x_value(point[:index]).strftime("%b %e")
              font_size = graph_font_marker_text[:size]
              text(point[:x] + 4, height - graph_padding_height - font_size*1.4, font_size*6) {
                string(date) {
                  font graph_font_marker_text
                  color graph_color_period_text
                }
              }
            end
          end
        else
          @points[lines[0]].each do |point|
            if calculated_x_value(point[:index]).strftime("%d") == "01"
              line(point[:x], graph_padding_height, point[:x], height - graph_padding_height) {
                stroke graph_stroke_periodic_line
              }
              date = calculated_x_value(point[:index]).strftime("%b")
              font_size = graph_font_marker_text[:size]
              text(point[:x] + 4, height - graph_padding_height - font_size*1.4, font_size*6) {
                string(date) {
                  font graph_font_marker_text
                  color graph_color_period_text
                }
              }
            end
          end
        end
      end
      
      def hover_stats
        return unless display_attributes_on_hover
        
        require "bigdecimal"
        require "perfect_shape/point"
        
        if @hover_point && lines && lines[0] && @points && @points[lines[0]] && !@points[lines[0]].empty?
          x = @hover_point[:x]
          closest_points = lines.map { |line| @points[line][@closest_point_index] }
          closest_x = closest_points[0]&.[](:x)
          closest_x_distance = PerfectShape::Point.point_distance(x.to_f, 0, closest_x.to_f, 0)
          # Today, we make the assumption that all lines have points along the same x-axis values
          # TODO In the future, we can support different x values along different lines
          if closest_x_distance < graph_point_distance_for_line(lines[0])
            line(closest_x, graph_padding_height, closest_x, height - graph_padding_height) {
              stroke graph_stroke_hover_line
            }
            closest_points.each_with_index do |closest_point, index|
              circle(closest_point[:x], closest_point[:y], 4) {
                fill lines[index][:stroke]
              }
              circle(closest_point[:x], closest_point[:y], 2) {
                fill :white
              }
            end
            text_label = formatted_x_value(@closest_point_index)
            text_label_width = estimate_width_of_text(text_label, DEFAULT_GRAPH_FONT_MARKER_TEXT)
            closest_point_texts = lines.map { |line| "#{line[:name]}: #{line[:y_values][@closest_point_index]}" }
            closest_point_text_widths = closest_point_texts.map do |text|
              estimate_width_of_text(text, graph_font_marker_text)
            end
            square_size = 12.0
            square_to_label_padding = 10.0
            label_padding = 10.0
            text_label_x = width - graph_padding_width - text_label_width - label_padding -
              (lines.size*(square_size + square_to_label_padding) + (lines.size - 1)*label_padding + closest_point_text_widths.sum)
            text_label_y = height + graph_padding_height

            text(text_label_x, text_label_y, text_label_width) {
              string(text_label) {
                font DEFAULT_GRAPH_FONT_MARKER_TEXT
                color graph_color_marker_text
              }
            }

            relative_x = text_label_x + text_label_width
            lines.size.times do |index|
              square_x = relative_x + label_padding

              square(square_x, text_label_y + 2, square_size) {
                fill lines[index][:stroke]
              }

              attribute_label_x = square_x + square_size + square_to_label_padding
              attribute_text = closest_point_texts[index]
              attribute_text_width = closest_point_text_widths[index]
              relative_x = attribute_label_x + attribute_text_width

              text(attribute_label_x, text_label_y, attribute_text_width) {
                string(attribute_text) {
                  font graph_font_marker_text
                  color graph_color_marker_text
                }
              }
            end
          end
        end
      end
      
      def formatted_x_value(x_value_index)
        # Today, we make the assumption that all lines have points along the same x-axis values
        # TODO In the future, we can support different x values along different lines
        graph_line = lines[0]
        x_value_format = graph_line[:x_value_format] || :to_s
        x_value = calculated_x_value(x_value_index)
        if (x_value_format.is_a?(Symbol) || x_value_format.is_a?(String))
          x_value.send(x_value_format)
        else
          x_value_format.call(x_value)
        end
      end
      
      def calculated_x_value(x_value_index)
        # Today, we make the assumption that all lines have points along the same x-axis values
        # TODO In the future, we can support different x values along different lines
        graph_line = lines[0]
        graph_line[:x_value_start] - (graph_line[:x_interval_in_seconds] * x_value_index)
      end
      
      def estimate_width_of_text(text_string, font_properties)
        font_size = font_properties[:size] || 16
        estimated_font_width = 0.6 * font_size
        text_string.chars.size * estimated_font_width
      end
      
    end
  end
end
