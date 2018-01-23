require 'tamashii/agent/event'
require 'tamashii/agent/handler/base'

module Tamashii
  module Agent
    module Handler
      class Buzzer < Base
        def resolve(data)
          Tamashii::Component.find(:buzzer).process_event(Tamashii::PwmBuzzer::Event.new(body: data))
        end
      end
    end
  end
end
