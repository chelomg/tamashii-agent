require 'tamashii/common'
require 'tamashii/client'
require 'tamashii/component'
require 'tamashii/has_component'
require 'pry'
module Tamashii
  module Agent
    class Config
      include Singleton

      class << self
        def respond_to_missing?(name, _all = false)
          super
        end

        def method_missing(name, *args, &block)
          # rubocop:disable Metrics/LineLength
          return instance.send(name, *args, &block) if instance.respond_to?(name)
          # rubocop:enable Metrics/LineLength
          super
        end
      end

      include Tamashii::Configurable
      include Tamashii::HasComponent

      AUTH_TYPES = [:none, :token]
      
      #config :connection_timeout, default: 3

      config :env, deafult: nil
      config :token

      config :localtime, default: "+08:00"

      config :lcd_animation_delay, default: 1

      component :networking, 'WebSocket'
      component :buzzer, 'PwmBuzzer'
      component :mfrc522_spi, 'Mfrc522Spi'

      def auth_type(type = nil)
        return @auth_type ||= :none if type.nil?
        return unless AUTH_TYPES.include?(type)
        @auth_type = type.to_sym
      end

      def log_level(level = nil)
        return Agent.logger.level if level.nil?
        Client.config.log_level(level)
        Agent.logger.level = level
      end

      def log_file(value = nil)
        return @log_file ||= STDOUT if value.nil?
        Client.config.log_file = value
        @log_file = value
      end

      [:use_ssl, :host, :port, :entry_point].each do |method_name|
        define_method(method_name) do |*args|
          Tamashii::Client.config.send(method_name, *args)
        end
      end

      def remove_component(name)
        self.components.delete(name)
      end

      def env(env = nil)
        return Tamashii::Environment.new(self[:env]) if env.nil?
        self.env = env.to_s
      end
    end
  end
end
