require 'tamashii/agent/handler/base'

module Tamashii
  module Agent
    module Handler
      class RemoteResponse < Base
        def resolve(data)
          @connection.handle_remote_response(self.type, data)
        end
      end
    end
  end
end
