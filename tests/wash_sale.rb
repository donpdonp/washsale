require 'wash_sale'

describe WashSale do
  before do
  end

  it "loads initial data" do
    initial_items = [ {"time" => "2011-02-01", "amount" => 20, "price" => 0} ]
    inventory = Inventory.new(initial_items)
    washer = WashSale.new(inventory)
    washer.must_be_instance_of WashSale
    washer.inventory.must_equal inventory
  end

  describe "handles wash sale cases" do
    before do
      @initial_items = [ {"time" => "2011-02-01", "amount" => 9, "price" => 0} ]
      @washer = WashSale.new(Inventory.new(@initial_items))
    end

    it "handles a sale" do
      row = '127,"2013-04-16 00:08:51",earned,"BTC sold: [tid:1000000000000000] 1.00000000 BTC at $83.02111",0.83519,526.87448'
      record = Statement.new(CSV.parse_line(row))
      @washer.wash_sale(record)
      correct_inventory = Inventory.new([{"time" => "2011-02-01", "amount" => 9, "price" => 0}])
      @washer.inventory.must_equal correct_inventory
    end

    it "handles a sale with insufficient inventory" do
      row = '127,"2013-04-16 00:08:51",earned,"BTC sold: [tid:1000000000000000] 15.00000000 BTC at $83.02111",0.83519,526.87448'
      record = Statement.new(CSV.parse_line(row))
      assert_raises(RuntimeError) do
        @washer.wash_sale(record)
      end
    end
  end
end