require "onyx-http/rescuer"

module Onyx::REST
  module Rescuers
    class REST < HTTP::Rescuers::Silent(Onyx::REST::Error)
      def fallback(context, error)
        context.response.status_code = error.code
        context.response << error.code << " " << error.message
      end
    end
  end
end
