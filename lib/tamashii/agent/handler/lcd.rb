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
          Tamashii::Component.find(:lcd).send_text(data)
          #case type
          #when Type::LCD_MESSAGE
          #  Tamashii::Component.find(:lcd).run_message(data)
          #when Type::LCD_SET_IDLE_TEXT
          #  Tamashii::Component.find(:lcd).run_idle_text(data)
          #end
        end
      end
    end
  end
end
