require "http-params-serializable"
require "../../error"

module Onyx::REST::Action
  class PathParamsError < REST::Error(400)
    def initialize(message : String, @path : Array(String))
      super(message)
    end

    def payload
      {path: @path}
    end
  end

  macro path(&block)
    struct PathParams
      include ::HTTP::Params::Serializable

      {% verbatim do %}
        macro getter(argument, **options, &block)
          {% if block %}
            {% raise "Path params do not support nesting" %}
          {% elsif argument.is_a?(TypeDeclaration) %}
            Object.getter {{argument}}
          {% else %}
            {% raise "BUG: Unhandled argument type #{argument.class_name}" %}
          {% end %}
        end
      {% end %}

      {{yield.id}}
    end

    @path = uninitialized PathParams
    getter path

    def initialize(@context : ::HTTP::Server::Context)
      {% if @type.overrides?(Onyx::REST::Action, "initialize") %}
        previous_def
      {% else %}
        super
      {% end %}

      @path = uninitialized PathParams

      begin
        @path = PathParams.new(@context.request.path_params.join('&'){ |(k, v)| "#{k}=#{v}" })
      rescue ex : ::HTTP::Params::Serializable::Error
        raise PathParamsError.new("Path p" + ex.message.not_nil![1..-1], ex.path)
      end
    end
  end
end
