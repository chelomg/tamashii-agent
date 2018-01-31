require 'tamashii/common'

module Tamashii
  module Agent
    module Handler
      class Base < Tamashii::Handler
        def initialize(*args, &block)
          super(*args, &block)
          @networking = self.env[:networking]
        end
      end
    end
  end
end
