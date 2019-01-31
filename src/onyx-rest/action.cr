require "http/server/context"
require "./action/*"
require "./ext/http/server/response/view"

# A callable REST action.
#
# An Action itself isn't responsible for rendering. It *should* return a `View` instance or
# explicitly set `HTTP::Server::Response#view` to a `View` instance with the `#view` method,
# and that view *should* be rendered in future handlers.
#
# Action params can be defined in `.path_params`, `.query_params`,
# `.form_params` and `.json_params` blocks.
#
# Action errors can be defined in the `.errors` block.
#
# ```
# struct Actions::GetUser
#   include Onyx::REST::Action
#
#   path_params do
#     type id : Int32
#   end
#
#   errors do
#     type UserNotFound(404), id : Int32
#   end
#
#   def call
#     user = find_user(path_params.id)
#     raise UserNotFound.new(path_params.id) unless user
#     return Views::User.new(user)
#   end
# end
#
# Actions::GetUser.call(env) # => Views::User instance, if not raised Params::Error or UserNotFound
# ```
#
# Router example:
#
# ```
# router = Atom::Handlers::Router.new do
#   get "/", Actions::GetUser
#   # Equivalent of
#   get "/" do |context|
#     begin
#       return_value = Actions::GetUser.call(context)
#       context.response.view = return_value if return_value.is_a?(Atom::View)
#     rescue e : Params::Error | Action::Error
#       context.response.error = e
#     end
#   end
# end
# ```
module Onyx::REST::Action
  # Where all the action takes place.
  abstract def call

  def initialize(@context : ::HTTP::Server::Context)
  end

  @body : String?

  # Lazy string version of request body (read `.max_body_size` bytes on the first call).
  #
  # NOTE: Will be `nil` if `.preserve_body` is set to `false` and read on params parsing.
  #
  # ```
  # # Action A
  # def call
  #   body                 # => "foo"
  #   context.request.body # => nil
  # end
  #
  # # Action B
  # def call
  #   context.request.body # => "foo"
  #   body                 # => likely to be nil, because already read above
  # end
  #
  # # Action C
  # params do
  #   type foo : String
  # end
  #
  # preserve_body = false
  #
  # def call
  #   body # => nil if request type was JSON or form etc.
  # end
  #
  # # Action D
  # params do
  #   type foo : String
  # end
  #
  # preserve_body = true
  #
  # def call
  #   body # => "bar" even after params parsing
  # end
  # ```
  protected def body
    @body ||= context.request.body.try &.gets(limit: self.class.max_body_size)
  end

  # Current HTTP::Server context.
  protected getter context : ::HTTP::Server::Context

  def view(view : View)
    context.response.view = view
  end

  # Set HTTP status code.
  #
  # ```
  # def call
  #   status(400)
  # end
  # ```
  protected def status(status : Int32)
    context.response.status_code = status
  end

  # Set HTTP header.
  #
  # ```
  # def call
  #   header("Content-Type", "application/json")
  # end
  # ```
  protected def header(name, value)
    context.response.headers[name] = value
  end

  # Set response status code to *code* and "Location" header to *location*.
  #
  # Does **not** interrupt the call.
  #
  # ```
  # def call
  #   redirect("https://google.com")
  #   text("will be called")
  # end
  # ```
  protected def redirect(location : String | URI, code = 302)
    status(code)
    header("Location", location.to_s)
  end
end
