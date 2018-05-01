require "spec_helper"

RSpec.describe ActionOperation::VERSION do
  it "should be a string" do
    expect(ActionOperation::VERSION).to be_kind_of(String)
  end
end
