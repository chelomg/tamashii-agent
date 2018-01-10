require 'tamashii/agent/event'
require 'tamashii/agent/handler/base'
require 'pry'

module Tamashii
  module Agent
    module Handler
      class Buzzer < Base
        def resolve(data)
          @master.send_event(Tamashii::PwmBuzzer::Event.new(:agent, body: data))
        end
      end
    end
  end
end
