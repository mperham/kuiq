# frozen_string_literal: true

require "kuiq/version"

module Kuiq
  WINDOW_WIDTH = 900.0
  WINDOW_HEIGHT = 560.0
  GRAPH_MAX_POINTS_LARGEST_SCREEN = 577
  GRAPH_DASHBOARD_COLORS = {
    processed: [47, 109, 104],
    failed: [163, 40, 39],
  }
  POLLING_INTERVAL_MIN = 1
  POLLING_INTERVAL_MAX = 20
  POLLING_INTERVAL_DEFAULT = 2
end
