require 'statement'
require 'csv'
require 'json'

describe Statement do
  describe "decodes mtgox csv" do
    it "parses a row" do
      line = '271,"2013-11-27 18:33:39",earned,"BTC sold: [tid:1000000000000000] 0.37440024 BTC at $950.00000",355.68023,1593.04407'
      Statement.new(mtgox_csv_row(line)).must_be_instance_of Statement
    end

    it "parses a row with thousands" do
      line = '335,"2013-12-10 19:47:57",spent,"BTC bought: [tid:1000000000000000] 0.06810673 BTC at $1,034.99000",70.48978,1993.63232'
      Statement.new(mtgox_csv_row(line)).must_be_instance_of Statement
    end
  end

  it "decodes json" do
    row = {"time" => "2011-02-01", "amount" => 220, "price" => 0}
    Statement.new(row).must_be_instance_of Statement
  end
end

def mtgox_csv_row(line)
  headers = ["Index", "Date", "Type", "Info", "Value", "Balance"]
  CSV::Row.new(headers, CSV.parse_line(line))
end