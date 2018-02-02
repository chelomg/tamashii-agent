require 'tamashii/agent/common'
require 'tamashii/agent/networking'
require 'tamashii/agent/keyboard_logger'
require 'tamashii/agent/event'
require 'tamashii/agent/common'
require 'tamashii/component/base'
Bundler.require(:components)
require 'tamashii/component/bus'
require 'tamashii/agent/event_handler'
require 'tamashii/agent/network_event_handler'
require 'pry'

module Tamashii
  module Agent
    class Master < Tamashii::Component::EventLoop
      include Common::Loggable

      attr_reader :serial_number

      def initialize
        super
        logger.info "Starting Tamashii::Agent #{Tamashii::Agent::VERSION} in #{Config.env} mode"
        @serial_number = get_serial_number
        logger.info "Serial number: #{@serial_number}"

        @networking = Tamashii::Agent::Networking.new

        bootstrap_components
        setup_handlers
        run_bus
      end

      def bootstrap_components
        Config.components.each do |name, klass|
          config = Config.send(name)
          Tamashii::Component.create_components(self, name, klass, config)
        end
        Tamashii::Component.start_components
      end

      def run_bus
        Tamashii::Component::Bus.subscribe(self)
        Tamashii::Component::Bus.start
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

      def setup_handlers
        @network_event_handler = Tamashii::Agent::NetworkEventHandler.new(self, @networking)

        EventHandler.register Tamashii::Mfrc522Spi::Event, &method(:process_card_event)

        EventHandler.register Tamashii::WebSocket::Event, &method(:process_networking_event)

        EventHandler.register Tamashii::Agent::Event, &method(:process_agent_event)
      end

      def process_card_event(event)
        if @networking.ready?
          id = event.body
          wrapped_body = {
            id: id,
            ev_body: event.body
          }.to_json
          @networking.new_remote_request(id, Type::RFID_NUMBER, wrapped_body)
        else
          logger.info "Connection not ready for #{event.type}:#{event.body}"
          Tamashii::Component.find(:buzzer).play_error
        end
      end

      def process_networking_event(event)
        @network_event_handler.exec(event)
      end

      def process_agent_event(event)
        case event.type
        when Event::RESTART_COMPONENT
          restart_component(event.body)
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
    end
  end
end
