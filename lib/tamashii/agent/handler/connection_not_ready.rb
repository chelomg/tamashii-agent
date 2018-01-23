require 'tamashii/agent/event'
require 'tamashii/agent/handler/base'

module Tamashii
  module Agent
    module Handler
      class ConnectionNotReady < Base
        def resolve(data)
          Tamashii::Component.find(:buzzer).process_event(Tamashii::PwmBuzzer::Event.new(body: "error"))
          #TODO: use lcd event
          #broadcast_event(Event.new(Event::LCD_MESSAGE, "Fatal Error\nConnection Error"))
        end
      end
    end
  end
end
