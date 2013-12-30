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

  describe "initial inventory 9 coins 0 dollars" do
    before do
      initial_coins = {time: "2011-02-01", amount: 9, price: 0}
      initial_fiat =  {time: "2011-02-01", amount: 0, price: 0}
      coins = Inventory.new('btc')
      coins << Statement.new(initial_coins)
      fiat = Inventory.new('usd')
      fiat << Statement.new(initial_fiat)
      @washer = WashSale.new(coins, fiat)
    end

    it "a sale of 1 coin" do
      row = '127,"2013-04-16 00:08:51",earned,"BTC sold: [tid:1000000000000000] 1.00000000 BTC at $83.00000",0.83519,526.87448'
      reductions = @washer.wash_sale(Statement.new(CSV.parse_line(row)))

      correct_coins = Inventory.new('btc')
      correct_coins << Statement.new({time: "2011-02-01", amount: 8, price: 0})
      correct_dollars = Inventory.new('usd')
      correct_dollars << Statement.new({time: "2011-02-01", amount: 0, price: 0})
      @washer.coins.must_equal correct_coins
      @washer.fiat.must_equal correct_dollars

      correct_taxes = [{time: "2013-04-16 00:08:51",
                        type:"ltcg", value:BigDecimal.new("83")}
                      ]
      @washer.taxes.must_equal correct_taxes.map{|t| Tax.new(t)}
    end

    it "a sale of 15 coins (insufficient inventory)" do
      row = '127,"2013-04-16 00:08:51",earned,"BTC sold: [tid:1000000000000000] 15.00000000 BTC at $83.02111",0.83519,526.87448'
      record = Statement.new(CSV.parse_line(row))
      assert_raises(RuntimeError) do
        @washer.wash_sale(record)
      end
    end
  end

  describe "initial inventory 0 coins 100 dollars" do
    before do
      initial_coins = {time: "2011-02-01", amount: 0, price: 0}
      initial_fiat =  {time: "2011-02-01", amount: 100, price: 0}
      coins = Inventory.new('btc')
      coins << Statement.new(initial_coins)
      fiat = Inventory.new('usd')
      fiat << Statement.new(initial_fiat)
      @washer = WashSale.new(coins, fiat)
    end

    it "purchase of 1 coin" do
      row = '8,"2013-04-17 00:00:00",spent,"BTC bought: [tid:10000] 1.00000000 BTC at $39.00000",13.24305,726.06053'
      taxes = @washer.wash_sale(Statement.new(CSV.parse_line(row)))

      correct_inventory = Inventory.new('btc')
      correct_inventory << Stametent.new({time: "2011-02-01", amount: 8, price: 0})
      correct_fiat = Inventory.new('usd')
      correct_inventory << Stametent.new({time: "2011-02-01", amount: 8, price: 0})
      @washer.dollars.must_equal correct_inventory

    end

    it "taxes" do
      correct_taxes = [{time: "2013-04-16 00:08:51",
                        type:"ltcg", value:BigDecimal.new("40")}
                      ]
      taxes = @washer.tax_check(Time.now)
      taxes.must_equal correct_taxes.map{|t| Tax.new(t)}
    end
  end
end