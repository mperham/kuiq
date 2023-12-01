# frozen_string_literal: true

require "kuiq/version"

module Kuiq
  WINDOW_WIDTH = 900.0
  WINDOW_HEIGHT = 500.0
  GRAPH_WIDTH = 885.0
  GRAPH_HEIGHT = 200.0
  GRAPH_PADDING_HEIGHT = 5.0
  GRAPH_PADDING_WIDTH = 5.0
  GRAPH_POINT_DISTANCE = 15.0
  GRAPH_MAX_POINTS = (GRAPH_WIDTH / GRAPH_POINT_DISTANCE).to_i + 2
  GRAPH_DASHBOARD_COLORS = {
    processed: [47, 109, 104],
    failed: [163, 40, 39],
  }
end
