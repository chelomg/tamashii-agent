module Tamashii
  module Agent
    module HasManageRemotePacket
      def process_packet(pkt)
        raise NotImplementedError, 'should implement process_packet method'
      end

      def resolve(pkt)
        raise NotImplementedError, 'should implement resolve method'
      end

      def exec_command(pkt)
        Handler::System.new(pkt.type, {networking: self}).resolve(pkt.body)
      end

      def process_lcd(pkt)
        Handler::Lcd.new(pkt.type, {networking: self}).resolve(pkt.body)
      end

      def process_buzzer(pkt)
        Handler::Buzzer.new(pkt.type, {networking: self}).resolve(pkt.body)
      end

      def process_rfid(pkt)
        Handler::RemoteResponse.new(pkt.type, {networking: self}).resolve(pkt.body)
      end
    end
  end
end
