module Kuiq
  module Model
    class Process
      def initialize(hash)
        @hash = hash
      end

      def method_missing(attr)
        @hash[attr.to_s]
      end

      def respond_to_missing?(attr, include_private = false)
        super || @hash.include?(attr.to_s)
      end
    end
  end
end
