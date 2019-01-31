module Onyx::REST::View
  macro json(&block)
    def to_json(json)
      build_json(json) do
        {{yield.id}}
      end
    end

    def build_json(json)
      with json yield
    end
  end

  macro json(value)
    def to_json(json)
      ({{value}}).to_json(json)
    end
  end

  macro text(&block)
    def to_text(io)
      io << ({{yield.id}})
    end
  end

  macro text(value)
    def to_text(io)
      io << ({{value}})
    end
  end
end
