# frozen_string_literal: true

require "quick/version"
require "sidekiq"
require "glimmer-dsl-libui"

# Redis is located at REDIS_URL || localhost:6379

module Quick
  class UI
    include Glimmer

    def run
      info = Sidekiq.default_configuration.redis_info
      window {
        margined true
        title "Sidekiq"
        horizontal_box {
          vertical_box {
            label "Redis Version"
            label info["redis_version"]
          }
          vertical_box {
            label "Used Memory"
            label info["used_memory_human"]
          }
        }
      }.show
    end
  end
end
