require 'tamashii/agent/common/loggable'
module Tamashii
  module Agent
    class NetworkEventHandler
      include Common::Loggable

      def initialize(agent, networking)
        @agent = agent
        @networking = networking
      end

      def exec(event)
        case event.type
        when :open then open
        when :close then close
        when :socket_closed then socket_closed
        when :message then message(event.body)
        when :error then error(event.body)
        end
      end

      def open
        logger.info "Server opened"
        @networking.auth_request
        @networking.send_auth_request([Tamashii::Type::CLIENT[:agent], @agent.get_serial_number, Config.token])
      end

      def close
        logger.info "Server closed normally"
      end

      def socket_closed
        logger.info "WS: Server socket closed"
        @networking.reset
      end

      def message(data)
        pkt = Packet.load(data)
        @networking.process_packet(pkt) if pkt
      end

      def error(e)
        logger.error("#{e.message}")
      end
    end
  end
end
