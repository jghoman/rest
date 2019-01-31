require "http-params-serializable"
require "json"
require "../../error"

module Onyx::REST::Action
  class JSONBodyError < REST::Error(400)
  end

  macro json(&block)
    struct JSONBody
      include JSON::Serializable

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
              include JSON::Serializable

              {% if block.body.is_a?(Expressions) %}
                {% for expression in block.body.expressions %}
                  JSONBody.{{expression}}
                {% end %}
              {% elsif block.body.is_a?(Call) %}
                JSONBody.{{yield.id}}
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

    @json = uninitialized JSONBody
    getter json

    def initialize(@context : HTTP::Server::Context)
      {% if @type.overrides?(Onyx::REST::Action, "initialize") %}
        previous_def
      {% else %}
        super
      {% end %}

      @json = uninitialized JSONBody

      begin
        if @context.request.headers["Content-Type"]?.try &.=~ /^application\/json/
          if body = @context.request.body
            @json = JSONBody.from_json(body.gets_to_end)
          else
            raise JSONBodyError.new("Missing request body")
          end
        else
          @json = JSONBody.from_json("{}")
        end
      rescue ex : JSON::MappingError
        raise JSONBodyError.new(ex.message.not_nil!.lines.first)
      end
    end
  end
end
