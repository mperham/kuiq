# Any methods defined here are available everywhere (both Models & Views) to provide extra convenience
# for handling cross-cutting concerns like logging and i18n.
#
# That said, defining Kernel methods must be done sparingly as it can be tough for codebase
# newcomers to figure out that global methods live here, and it would be better for maintainability
# in general to call methods on objects instead of inheriting global utility methods.
module Kernel
  # We will return Sidekiq.logger instead of Glimmer::Config.logger
  # because in general, GUI error logging is at the error level
  # and Sidekiq logging is at the info level, and we do not want
  # to see GUI info logging as it can be very verbose.
  #
  # In the future, if there is a need to unite the two loggers, we could
  # set `Glimmer::Config.logger = Sidekiq.logger` right after loading
  # both the sidekiq and glimmer-dsl-libui gems.
  def logger
    Sidekiq.logger
  end

  def t(msg, options = {})
    Kuiq::I18n.t(msg, options)
  end

  # Inverse-translates (e.g. for "Tableau de Bord" in fr, we get "Dashboard")
  def it(msg, options = {})
    Kuiq::I18n.it(msg, options)
  end

  def timeago_in_words(from_time, to_time = Time.now)
    from_time, to_time = to_time, from_time if from_time > to_time
    distance_in_minutes = ((to_time - from_time) / 60.0).round
    distance_in_seconds = (to_time - from_time).round

    case distance_in_minutes
    when 0
      case distance_in_seconds
      when ..4 then "0s"
      when 5..9 then "5s"
      when 10..19 then "15s"
      when 20..39 then "30s"
      else "1m"
      end

    when 1...90
      "#{distance_in_minutes}m"
    when 90...2520
      "#{(distance_in_minutes.to_f / 60.0).round}h"
    else
      "#{(distance_in_minutes.to_f / 1440.0).round}d"
    end
  end
end
