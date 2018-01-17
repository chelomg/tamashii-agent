require 'tamashii/agent/event'
require 'tamashii/agent/handler/base'
require 'pry'

module Tamashii
  module Agent
    module Handler
      class Buzzer < Base
        def resolve(data)
          Tamashii::Component::Bus.create(Tamashii::PwmBuzzer::Event.new(body: data))
        end
      end
    end
  end
end
