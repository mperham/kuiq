# frozen_string_literal: true

require "kuiq/version"

module Kuiq
  WINDOW_WIDTH = 900.0
  WINDOW_HEIGHT = 530.0
  GRAPH_WIDTH = 885.0
  GRAPH_HEIGHT = 200.0
  GRAPH_STATUS_HEIGHT = 30.0
  GRAPH_TEXT_WIDTH = 200.0
  GRAPH_PADDING_HEIGHT = 5.0
  GRAPH_PADDING_WIDTH = 5.0
  GRAPH_POINT_DISTANCE = 15.0
  GRAPH_MAX_POINTS = (GRAPH_WIDTH / GRAPH_POINT_DISTANCE).to_i + 1
  GRAPH_DASHBOARD_COLORS = {
    processed: [47, 109, 104],
    failed: [163, 40, 39],
    grid: [185, 184, 185],
    marker: [204, 203, 203],
    marker_dotted_line: [217, 217, 217],
    marker_text: [96, 96, 96],
    selection_stats: [133, 133, 133],
  }
  POLLING_INTERVAL_MIN = 1
  POLLING_INTERVAL_MAX = 20
  POLLING_INTERVAL_DEFAULT = 2
end
