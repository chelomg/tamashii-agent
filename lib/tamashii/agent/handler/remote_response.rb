require 'tamashii/agent/handler/base'

require 'tamashii/agent/common/loggable'

module Tamashii
  module Agent
    module Handler
      class RemoteResponse < Base
        include Tamashii::Agent::Common::Loggable
        def resolve(data)
          handle_remote_response(self.type, data)
        end

        #When data is back 
        def handle_remote_response(ev_type, wrapped_ev_body)
          logger.debug "Remote packet back: #{ev_type} #{wrapped_ev_body}"
          result = JSON.parse(wrapped_ev_body)
          id = result["id"]
          ev_body = result["ev_body"]
          # fetch ivar and delete it
          if ivar = @networking.future_ivar_pool.delete(id)
            ivar.set(ev_type: ev_type, ev_body: ev_body)
            case ev_type
            when Type::RFID_RESPONSE_JSON
              logger.debug "Handled: #{ev_type}: #{ev_body}"
              handle_card_result(ev_body)
            else
              logger.warn "Unhandled packet result: #{res_ev_type}: #{res_ev_body}"
            end
          else
            logger.warn "IVar #{id} not in pool"
          end
        end

        def handle_card_result(result)
          if result["auth"]
            Tamashii::Component.find(:buzzer).play_ok
          else
            Tamashii::Component.find(:buzzer).play_no
          end
          if result["message"]
            #@master.send_event(Event.new(Event::LCD_MESSAGE, result["message"]))
          end
        end
      end
    end
  end
end
