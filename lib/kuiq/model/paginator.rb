require 'sidekiq/paginator'
require 'singleton'

module Kuiq
  module Model
    class Paginator
      include Sidekiq::Paginator
      include Singleton
    end
  end
end
