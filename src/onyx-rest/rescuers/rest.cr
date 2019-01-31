require "onyx-http/rescuer"

module Onyx::REST
  module Rescuers
    class REST < HTTP::Rescuers::Silent(Onyx::REST::Error)
      def fallback(context, error)
        raise error
      end
    end
  end
end
