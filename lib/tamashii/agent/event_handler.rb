module Tamashii
  module Agent
    class EventHandler
      class << self
        def method_missing(name, *args, &block)
          self.instance.send(name, *args, &block)
        end

        def instance
          @instance ||= self.new
        end
      end

      def handlers
        @handlers ||= {}
      end

      def register(event, &block)
        handlers[event] = block
      end

      def resolve(event)
        handlers[event.class].call(event)
      end
    end
  end
end
