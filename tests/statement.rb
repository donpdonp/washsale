require 'statement'

describe Statement do
  it "can begin" do
    Statement.new([]).must_be_instance_of Statement
  end
end