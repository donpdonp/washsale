require 'statement'

describe Statement do
  it "decodes an mtgox csv line" do
    csv_rows = [
      '271,"2013-11-27 18:33:39",earned,"BTC sold: [tid:1000000000000000] 0.37440024 BTC at $950.00000",355.68023,1593.04407',
      '335,"2013-12-10 19:47:57",spent,"BTC bought: [tid:1000000000000000] 0.06810673 BTC at $1,034.99000",70.48978,1993.63232',
       ]
    Statement.new(csv_rows).must_be_instance_of Statement
  end
end
