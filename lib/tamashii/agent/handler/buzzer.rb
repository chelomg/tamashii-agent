require 'tamashii/agent/event'
require 'tamashii/agent/handler/base'

module Tamashii
  module Agent
    module Handler
      class Buzzer < Base
        def resolve(data)
          case data
          when "ok"
            Tamashii::Component.find(:buzzer).play_ok
          when "no"
            Tamashii::Component.find(:buzzer).play_no
          when "error"
            Tamashii::Component.find(:buzzer).play_error
          end
          
        end
      end
    end
  end
end
