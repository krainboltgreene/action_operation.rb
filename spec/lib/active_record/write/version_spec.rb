require "spec_helper"

RSpec.describe ActiveRecord::Write::VERSION do
  it "is a string" do
    expect(ActiveRecord::Write::VERSION).to be_kind_of(String)
  end
end
