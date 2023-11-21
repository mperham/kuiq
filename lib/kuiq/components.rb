# Views (Components)

class GlobalStat
  include Glimmer::LibUI::CustomControl

  option :job_manager
  option :k
  option :v

  body {
    vertical_box {
      label {
        text <= [job_manager, v,
          on_read: ->(jobs_array) {
            job_manager.send(v).to_s
          }]
      }

      label(k.to_s)
    }
  }
end

class GlobalStats
  include Glimmer::LibUI::CustomControl

  option :job_manager

  body {
    horizontal_box {
      stretchy false

      Job::STATUSES.each_pair do |k, v|
        global_stat(job_manager: job_manager, k:, v:)
      end
    }
  }
end

class DashboardGraph
  include Glimmer::LibUI::CustomControl

  option :job_manager

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
        body_root.queue_redraw_all
        time_remaining = job_manager.polling_interval
      end
    end
  end

  body {
    area {
      stretchy false

      rectangle(0, 0, 800, 200) {
        fill 255, 255, 255
      }

      on_draw do
        last_point = nil
        job_manager.report_points.each do |point|
          circle(point.first, point.last, 3) {
            fill 0, 128, 0
          }
          if last_point
            line(last_point.first, last_point.last, point.first, point.last) {
              stroke 0, 128, 0, thickness: 2
            }
          end
          last_point = point
        end
      end
    }
  }
end

class Dashboard
  include Glimmer::LibUI::CustomControl

  option :job_manager

  body {
    vertical_box {
      global_stats(job_manager: job_manager)

      horizontal_box {
        label("Dashboard") {
          stretchy false
        }

        # filler
        label

        vertical_box {
          horizontal_box {
            label("Polling interval:") {
              stretchy false
            }

            label {
              text <= [job_manager, :polling_interval,
                on_read: ->(val) { "#{val} sec" }]
            }
          }

          slider(1, 10) {
            value <=> [job_manager, :polling_interval]
          }
        }
      }

      dashboard_graph(job_manager: job_manager)

      horizontal_box {
        vertical_box {
          label "Redis Version"
          label job_manager.redis_info["redis_version"]
        }
        vertical_box {
          label "Uptime"
          label job_manager.redis_info["uptime_in_days"]
        }
        vertical_box {
          label "Connections"
          label job_manager.redis_info["connected_clients"]
        }
        vertical_box {
          label "Used Memory"
          label job_manager.redis_info["used_memory_human"]
        }
        vertical_box {
          label "Peak Used Memory"
          label job_manager.redis_info["used_memory_peak_human"]
        }
      }

      status_bar(job_manager: job_manager)
    }
  }
end

class StatusBar
  include Glimmer::LibUI::CustomControl

  option :job_manager

  before_body do
    @text_font_family = (OS.mac? ? "Helvetica" : "Arial")
    @text_font_size = (OS.mac? ? 14 : 11)
    @text_font = {family: @text_font_family, size: @text_font_size}
    @text_color = :grey
    @background_color = :black
  end

  body {
    area {
      rectangle(0, 0, 800, 30) {
        fill @background_color
      }

      text(20, 5, 100) {
        string("Sidekiq v#{Sidekiq::VERSION}") {
          font @text_font
          color @text_color
        }
      }

      text(120, 5, 160) {
        string(job_manager.redis_url) {
          font @text_font
          color @text_color
        }
      }

      text(280, 5, 100) {
        string(job_manager.current_time.strftime("%T UTC")) {
          font @text_font
          color @text_color
        }
      }

      text(380, 5, 100) {
        string("docs") {
          font @text_font
          color :red
        }

        # on_mouse_up do
        #   system "open #{job_manager.docs_url}"
        # end
      }

      text(480, 5, 100) {
        string(job_manager.locale) {
          font @text_font
          color :red
        }

        # on_mouse_up do
        #   system "open #{job_manager.locale_url}"
        # end
      }
    }
  }
end
