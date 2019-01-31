require "http-params-serializable"
require "../../error"

module Onyx::REST::Action
  class QueryParamsError < REST::Error(400)
    def initialize(message : String, @path : Array(String))
      super(message)
    end

    def payload
      {path: @path}
    end
  end

  macro query(&block)
    struct QueryParams
      include ::HTTP::Params::Serializable

      {% verbatim do %}
        macro getter(argument, **options, &block)
          {% if block %}
            {% if argument.is_a?(Path) %}
              {% raise "Cannot declare namespaced nested query parameter" if argument.names.size > 1 %}

              Object.getter {{argument.names.first.underscore}} : {{argument.names.first.camelcase.id}}
            {% elsif argument.is_a?(Call) %}
              Object.getter {{argument.name.underscore}} : {{argument.name.camelcase.id}}
            {% else %}
              {% raise "BUG: Unhandled argument type #{argument.class_name}" %}
            {% end %}

            {% if argument.is_a?(Path) %}
              struct {{argument.names.first.camelcase.id}}
            {% elsif argument.is_a?(Call) %}
              struct {{argument.name.camelcase.id}}
            {% end %}
              include ::HTTP::Params::Serializable

              {% if block.body.is_a?(Expressions) %}
                {% for expression in block.body.expressions %}
                  QueryParams.{{expression}}
                {% end %}
              {% elsif block.body.is_a?(Call) %}
                QueryParams.{{yield.id}}
              {% else %}
                {% raise "BUG: Unhandled block body type #{block.body.class_name}" %}
              {% end %}
            end
          {% elsif argument.is_a?(TypeDeclaration) %}
            Object.getter {{argument}}
          {% else %}
            {% raise "BUG: Unhandled argument type #{argument.class_name}" %}
          {% end %}
        end
      {% end %}

      {{yield.id}}
    end

    @query = uninitialized QueryParams
    getter query

    def initialize(@context : ::HTTP::Server::Context)
      {% if @type.overrides?(Onyx::REST::Action, "initialize") %}
        previous_def
      {% else %}
        super
      {% end %}

      @query = uninitialized QueryParams

      begin
        @query = QueryParams.new(@context.request.query.to_s)
      rescue ex : ::HTTP::Params::Serializable::Error
        raise QueryParamsError.new("Query p" + ex.message.not_nil![1..-1], ex.path)
      end
    end
  end
end
