require 'tamashii/agent/event'
require 'tamashii/agent/handler/base'
require 'tamashii/agent/common/loggable'

module Tamashii
  module Agent
    module Handler
      class System < Base
        include Tamashii::Agent::Common::Loggable
        def resolve(data)
          process_system_command(type.to_s)
        end

        def process_system_command(type)
          logger.info "System command code: #{type}"
          case type.to_i
          when Tamashii::Type::REBOOT
            system_reboot
          when Tamashii::Type::POWEROFF
            system_poweroff
          when Tamashii::Type::RESTART
            system_restart
          when Tamashii::Type::UPDATE
            system_update
          end
        end

        def show_message(message)
          logger.info message
          broadcast_event(Event.new(Event::LCD_MESSAGE, message))
          sleep 1
        end

        def system_reboot
          show_message "Rebooting"
          system("reboot &")
        end

        def system_poweroff
          show_message "Powering  Off"
          system("poweroff &")
        end

        def system_restart
          show_message "Restarting"
          system("systemctl restart tamashii-agent.service &")
        end

        def system_update
          show_message("Updating")
          system("gem update tamashii-agent")
          system_restart
        end
      end
    end
  end
end
