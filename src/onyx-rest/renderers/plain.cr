require "onyx-http/ext/http/server/response/error"

require "http/server/handler"

require "../ext/http/server/response/view"
require "../error"

module Onyx::REST
  # HTTP handlers which render content.
  module Renderers
    # A plain text renderer.
    # Should be put after processor (i.e. `Onyx::REST::Processor`).
    # Calls the next handler if it's present.
    class Plain
      include ::HTTP::Handler

      # :nodoc:
      def call(context)
        context.response.content_type = "text/plain; charset=utf-8"

        if error = context.response.error
          message = "Internal Server Error"
          code = 500
          payload = nil

          if error.is_a?(REST::Error)
            code = error.code
            message = error.message
            payload = error.payload
          end

          context.response.status_code = code
          context.response << code << " " << message
        elsif view = context.response.view
          context.response << view.to_s
        end

        if self.next
          call_next(context)
        end
      end
    end
  end
end
