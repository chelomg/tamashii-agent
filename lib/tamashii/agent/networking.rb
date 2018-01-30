require 'aasm'
require 'json'
require 'concurrent'

require 'tamashii/common'
require 'tamashii/agent/common'

require 'tamashii/agent/config'
require 'tamashii/agent/event'
require 'tamashii/agent/component'

require 'tamashii/agent/handler'

require 'tamashii/client'

module Tamashii
  module Agent
    class Networking
      include Common::Loggable
      class RequestTimeoutError < RuntimeError; end

      include AASM

      aasm do
        state :init, initial: true
        state :auth_pending
        state :ready

        event :auth_request do
          transitions from: :init, to: :auth_pending, after: Proc.new { logger.info "Sending authentication request" }
        end

        event :auth_success do
          transitions from: :auth_pending, to: :ready, after: Proc.new { logger.info "Authentication finished. Tag = #{@tag}" }
        end

        event :reset do
          transitions to: :init, after: Proc.new { logger.info "Connection state reset" }
        end
      end

      def initialize
        self.reset
        @tag = 0
        @future_ivar_pool = Concurrent::Map.new
      end

      def future_ivar_pool
        @future_ivar_pool
      end

      def try_send_request(ev_type, ev_body)
        if self.ready?
          Tamashii::Component.find(:networking).send_request(Packet.new(ev_type, @tag, ev_body).dump)
          true
        else
          false
        end
      end

      def send_auth_request(auth_array)
        # TODO: other types of auth
        if Tamashii::Component.find(:networking).send_request(Packet.new(Tamashii::Type::AUTH_TOKEN, 0, auth_array.join(",")).dump)
          logger.debug "Auth sent!"	
        else
          logger.error "Cannot sent auth request!"
	end
      end

      def schedule_task_runner(id, ev_type, ev_body, start_time, times)
        logger.debug "Schedule send attemp #{id} : #{times + 1} time(s)"
        if try_send_request(ev_type, ev_body)
          # Request sent, do nothing
          logger.debug "Request sent for id = #{id}"
        else
          if Time.now - start_time < Config.connection_timeout
            # Re-schedule self
            logger.warn "Reschedule #{id} after 1 sec"
            schedule_next_task(1, id,  ev_type, ev_body, start_time, times + 1)
          else
            # This job is expired. Do nothing
            logger.warn "Abort scheduling #{id}"
          end
        end
      end

      def schedule_next_task(interval, id, ev_type, ev_body, start_time, times)
        Concurrent::ScheduledTask.execute(interval, args: [id, ev_type, ev_body, start_time, times], &method(:schedule_task_runner))
      end

      def create_request_scheduler_task(id, ev_type, ev_body)
        schedule_next_task(0, id, ev_type, ev_body, Time.now, 0)
      end

      def create_request_async(id, ev_type, ev_body)
        req = Concurrent::Future.new do
          # Create IVar for store result
          ivar = Concurrent::IVar.new
          @future_ivar_pool[id] = ivar
          # Schedule to get the result
          create_request_scheduler_task(id, ev_type, ev_body)
          # Wait for result
          if result = ivar.value(Config.connection_timeout)
            # IVar is already removed from pool
            result
          else
            # Manually remove IVar
            # Any fulfill at this point is useless
            logger.error "Timeout when getting IVar for #{id}"
            @future_ivar_pool.delete(id)
            logger.error "#{id} Failed with Request Timeout"
            on_request_timeout(ev_type, ev_body)
          end
        end
        req.execute
        req
      end

      def new_remote_request(id, ev_type, ev_body)
        # enqueue if not exists
        if !@future_ivar_pool[id]
          create_request_async(id, ev_type, ev_body)
          logger.debug "Request created: #{id}"
        else
          logger.warn "Duplicated id: #{id}, ignored"
        end
      end
      
      def on_request_timeout(ev_type, ev_body)
        logger.info "Connection not ready for #{ev_type}:#{ev_body}"
        Tamashii::Component.find(:buzzer).play_error
      end
    end
  end
end

