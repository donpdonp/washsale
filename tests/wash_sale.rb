require 'wash_sale'

describe WashSale do
  before do
  end

  it "start with empty inventory" do
    washer = WashSale.new(Inventory.new('btc'), Inventory.new('usd'))
    washer.must_be_instance_of WashSale
    washer.coins.total.must_equal 0
    washer.fiat.total.must_equal 0
  end

  describe "handles sales from inventory 9" do
    before do
      initial_coins = {time: "2011-02-01", amount: 9, price: 0}
      initial_fiat =  {time: "2011-02-01", amount: 0, price: 0}
      coins = Inventory.new('btc')
      coins << Statement.new(initial_coins)
      fiat = Inventory.new('usd')
      fiat << Statement.new(initial_fiat)
      @washer = WashSale.new(coins, fiat)
    end

    it "handles a sale of 1 coin" do
      row = '127,"2013-04-16 00:08:51",earned,"BTC sold: [tid:1000000000000000] 1.00000000 BTC at $83.00000",0.83519,526.87448'
      taxes = @washer.wash_sale(Statement.new(CSV.parse_line(row)))

      correct_inventory = Inventory.new({coins: [{time: "2011-02-01", amount: 8, price: 0}],
                                         dollars: BigDecimal.new("83")})
      @washer.inventory.must_equal correct_inventory

      correct_taxes = [{time: "2013-04-16 00:08:51",
                        type:"ltcg", value:BigDecimal.new("83")}
                      ]
      taxes.must_equal correct_taxes.map{|t| Tax.new(t)}
    end

    it "handles a sale of 1 coin then a buy of 1 coin" do
      row = '7,"2013-04-16 00:08:51",earned,"BTC sold: [tid:100000] 1.00000000 BTC at $40.00000",0.83519,526.87448'
      taxes = @washer.wash_sale(Statement.new(CSV.parse_line(row)))

      correct_inventory = Inventory.new({coins: [{time: "2011-02-01", amount: 8, price: 0}],
                                         dollars: BigDecimal.new("40")})
      @washer.inventory.must_equal correct_inventory

      row = '8,"2013-04-17 00:00:00",spent,"BTC bought: [tid:10000] 1.00000000 BTC at $39.00000",13.24305,726.06053'
      taxes = @washer.wash_sale(Statement.new(CSV.parse_line(row)))

      correct_inventory = Inventory.new({coins: [{time: "2011-02-01", amount: 8, price: 0},
                                                 {time: "2013-04-17", amount: 1, price: 39}],
                                         dollars: BigDecimal.new("1")})
      @washer.inventory.must_equal correct_inventory

      correct_taxes = [{time: "2013-04-16 00:08:51",
                        type:"ltcg", value:BigDecimal.new("40")}
                      ]
      @washer.taxes.must_equal correct_taxes.map{|t| Tax.new(t)}
    end

    it "handles a sale of 15 coins (insufficient inventory)" do
      row = '127,"2013-04-16 00:08:51",earned,"BTC sold: [tid:1000000000000000] 15.00000000 BTC at $83.02111",0.83519,526.87448'
      record = Statement.new(CSV.parse_line(row))
      assert_raises(RuntimeError) do
        @washer.wash_sale(record)
      end
    end
  end
end