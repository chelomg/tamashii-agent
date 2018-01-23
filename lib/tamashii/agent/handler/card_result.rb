require 'tamashii/agent/event'
require 'tamashii/agent/handler/base'

module Tamashii
  module Agent
    module Handler
      class CardResult < Base
        def resolve(data)
          data = JSON.parse(data)
          if data["auth"]
            Tamashii::Component.find(:buzzer).process_event(Tamashii::PwmBuzzer::Event.new(body: "ok"))
          else
            Tamashii::Component.find(:buzzer).process_event(Tamashii::PwmBuzzer::Event.new(body: "no"))
          end
          if data["message"]
            #TODO: use lcd event
            #Tamashii::Component.find(:lcd).process_event(Tamashii::LCD.new(message: result["message"])
          end
        end
      end
    end
  end
end
