require 'tamashii/agent/common'
require 'tamashii/agent/networking'
require 'tamashii/agent/lcd'
require 'tamashii/agent/buzzer'
require 'tamashii/agent/card_reader'
require 'tamashii/agent/keyboard_logger'
require 'tamashii/agent/event'
require 'tamashii/agent/common'
require 'tamashii/component/base'
Bundler.require(:components)
require 'tamashii/component/bus'
require 'tamashii/agent/event_handler'
require 'tamashii/agent/handler'
require 'tamashii/web_socket/type'
require 'pry'

module Tamashii
  module Agent
    class Master < Tamashii::Component::Base
      include Common::Loggable

      attr_reader :serial_number

      def initialize
        super
        logger.info "Starting Tamashii::Agent #{Tamashii::Agent::VERSION} in #{Config.env} mode"
        @serial_number = get_serial_number
        logger.info "Serial number: #{@serial_number}"
        start
        setup_networking_resolver
        setup_event_handler
        Tamashii::Component::Bus.subscribe(self)
        Tamashii::Component::Bus.start
      end

      def start
        Config.components.each do |name, klass|
          config = Config.send(name)
          Tamashii::Component.bootstrap(self, name, klass, config)
        end
      end

      #override
      def run!
        loop do
          until @event_queue.empty? do
            @event_queue.pop(true).call
          end
        end
      end

      #override
      def clean_up
      end

      #override
      def send_event(event)
        @event_queue << lambda do
          process_event(event)
        end
      end

      def get_serial_number
        serial = ENV['SERIAL_NUMBER']
        serial = read_serial_from_cpuinfo if serial.nil?
        serial = "#{Config.env}_pid_#{Process.pid}".upcase if serial.nil?
        serial
      end

      def read_serial_from_cpuinfo
        return nil unless File.exists?("/proc/cpuinfo")
        File.open("/proc/cpuinfo") do |f|
          content = f.read
          if content =~ /Serial\s*:\s*(\w+)/
            return $1
          end
        end
      end

      def restart_component(name)
        if old_component = @components[name]
          params = Config.components[name]
          logger.info "Stopping component: #{name}"
          old_component.stop # TODO: set timeout for stopping?
          logger.info "Restarting component: #{name}"
          create_component(name, params)
        else
          logger.error "Restart component failed: unknown component #{name}"
        end
      end

      def setup_networking_resolver
        env_data = {networking: Tamashii::Component.find(:networking), master: self}
        Resolver.config do
          [Type::REBOOT, Type::POWEROFF, Type::RESTART, Type::UPDATE].each do |type|
            handle type,  Handler::System, env_data
          end
          [Type::LCD_MESSAGE, Type::LCD_SET_IDLE_TEXT].each do |type|
            handle type,  Handler::Lcd, env_data
          end
          handle Type::BUZZER_SOUND,  Handler::Buzzer, env_data

          handle WebSocket::Type::CONNECTION_NOT_READY, Handler::ConnectionNotReady
          handle WebSocket::Type::CARD_RESULT, Handler::CardResult
        end
      end

      def setup_event_handler
        EventHandler.register(Tamashii::Mfrc522Spi::Event) do |event|
          Tamashii::Component.find(:networking).process_event(event)
        end

        EventHandler.register(Tamashii::WebSocket::Event) do |event|
          Resolver.resolve(event)
        end

        EventHandler.register(Tamashii::Agent::Event) do |event|
          case event.type
          when Event::RESTART_COMPONENT
            restart_component(event.body)
          end
        end
      end

      #override
      def process(event)
        logger.debug "Got event: #{event.class}, #{event.body}"
        EventHandler.resolve(event)
      end

      # may remove
      # override
      def process_event(event)
        super
      end

      # override
      def stop
        super
        Tamashii::Component.stop
        logger.info "Master stopped"
      end


      def broadcast_event(event)
        Tamashii::Component.find_all.each_value do |c|
          c.run(:receive, event)
        end
      end

      def config
        Config
      end
    end
  end
end
