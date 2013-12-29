require 'wash_sale'

describe WashSale do
  before do
  end

  it "loads initial data" do
    @initial_items = [ {"time" => "2011-02-01", "amount" => 220, "price" => 0} ]
    WashSale.new(@initial_items).must_be_instance_of WashSale
  end

  describe "handles wash sale cases" do
    before do
      @initial_items = [ {"time" => "2011-02-01", "amount" => 220, "price" => 0} ]
      @washer = WashSale.new(@initial_items)
    end

    it "handles a sale" do
      row = '127,"2013-04-16 00:08:51",earned,"BTC sold: [tid:1366070931097125] 0.01006000 BTC at $83.02111",0.83519,526.87448'
      record = Statement.new(CSV.parse_line(row))
      @washer.wash_sale(record)
    end
  end
end