require 'tamashii/agent/event'
require 'tamashii/agent/handler/base'
require 'tamashii/agent/common/loggable'

module Tamashii
  module Agent
    module Handler
      class Lcd < Base
        include Tamashii::Agent::Common::Loggable
        def resolve(data)
          logger.debug "TODO: LCD process"
          logger.debug "#{data}"
          #case type
          #when Type::LCD_MESSAGE
          #  @master.send_event(Event.new(Event::LCD_MESSAGE, data))
          #when Type::LCD_SET_IDLE_TEXT
          #  @master.send_event(Event.new(Event::LCD_SET_IDLE_TEXT, data))
          #end
        end
      end
    end
  end
end
