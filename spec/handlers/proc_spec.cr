require "../spec_helper"
require "../../src/atom/handlers/proc"

class Atom::Handlers::Proc
  def call_next(context)
    context.response.print("next")
  end
end

describe Atom::Handlers::Proc do
  handler = Atom::Handlers::Proc.new do |handler, context|
    if context.request.query_params.to_h["pass"]? == "true"
      handler.call_next(context)
    end
  end

  it do
    response = handle_request(handler)
  end

  context "when pass" do
    response = handle_request(handler, Req.new("GET", "/?pass=true"))

    it "calls next" do
      response.body.should eq "next"
    end
  end

  context "when not pass" do
    response = handle_request(handler, Req.new("GET", "/?pass=false"))

    it "calls next" do
      response.body.empty?.should be_true
    end
  end
end