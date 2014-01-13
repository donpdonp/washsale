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

  describe "initial inventory 9 coins(2011) 0 dollars" do
    before do
      coins = Inventory.new('btc')
      initial_coins = {time: "2011-02-01", amount: 9, price: 0, txid: "mined1"}
      coins << Statement.new(initial_coins)

      fiat = Inventory.new('usd')

      @washer = WashSale.new(coins, fiat)
    end

    it "a sale of 1 longterm coin" do
      row = '127,"2013-04-16 00:00:00",earned,"BTC sold: [tid:1000000000000000] 1.00000000 BTC at $83.00000",0.83519,526.87448'
      reductions = @washer.wash_sale(Statement.new(CSV.parse_line(row)))

      correct_coins = Inventory.new('btc')
      correct_coins << Statement.new({time: "2011-02-01", amount: 9, reduced: 1, price: 0})
      correct_dollars = Inventory.new('usd')
      correct_dollars << Statement.new({time: "2013-04-16", amount: 83, price: 1})
      @washer.coins.must_equal correct_coins
      @washer.fiat.must_equal correct_dollars

      # longterm sale is an immediate tax
      correct_taxes = [{time: "2013-04-16",
                        type:"ltcg", value:83}
                      ].map{|t| Tax.new(t)}
      taxes = @washer.tax_check(@washer.fiat.balances, Time.parse("2013-06-01"))
      taxes.must_equal correct_taxes
    end

    it "a sale of 15 coins (insufficient inventory)" do
      row = '127,"2013-04-16 00:08:51",earned,"BTC sold: [tid:1000000000000000] 15.00000000 BTC at $83.02111",0.83519,526.87448'
      record = Statement.new(CSV.parse_line(row))
      assert_raises(RuntimeError) do
        @washer.wash_sale(record)
      end
    end
  end

  describe "initial inventory 0 coins 39 dollars" do
    before do
      coins = Inventory.new('btc')

      fiat = Inventory.new('usd')
      initial_fiat =  {time: "2013-02-01", amount: 39, price: 0, txid: "deposit1"}
      fiat << Statement.new(initial_fiat)

      @washer = WashSale.new(coins, fiat)
    end

    it "purchase of 1 coin" do
      row = '8,"2013-04-17 00:00:00",spent,"BTC bought: [tid:10000] 1.00000000 BTC at $39.00000",13.24305,726.06053'
      @washer.wash_sale(Statement.new(CSV.parse_line(row)))

      correct_coins = Inventory.new('btc')
      correct_coins << Statement.new({time: "2013-04-17", amount: 1, price: 39})
      @washer.coins.must_equal correct_coins

      correct_fiat = Inventory.new('usd')
      correct_fiat << Statement.new({time: "2013-02-01", amount: 39, reduced: 39, price: 0, txid: "1z"})
      @washer.fiat.must_equal correct_fiat

      # no tax on a purchase
      @washer.taxes.must_equal []
    end

  end

  describe "inventory buy, sell 1 day later" do
    before do
      coins = Inventory.new('btc')
      buy = Statement.new({time: "2013-01-30", amount: 0, price: 0})
      coins << buy

      fiat = Inventory.new('usd')
      initial_fiat =  {time: "2013-02-01", amount: 100, price: 0, txid: "A23", link: buy}
      fiat << Statement.new(initial_fiat)

      @washer = WashSale.new(coins, fiat)
    end

    it "taxes 1 day after the sale" do
      @washer.tax_check(@washer.fiat.balances, Time.parse("2013-02-02"))
      @washer.taxes.must_equal []
    end

    it "taxes 60 days after the sale" do
      correct_taxes = [{time: "2013-02-01",
                        type:"stcg", value:100}
                      ].map{|t| Tax.new(t)}
      @washer.tax_check(@washer.fiat.balances, Time.parse("2013-04-02"))
      @washer.taxes.must_equal correct_taxes
    end
  end

  describe "buy today, sell 1 day later, buy back 2 days later" do
    before do
      coins = Inventory.new('btc')
      @buy = Statement.new({time: "2013-01-30", amount: 0, price: 0})
      coins << @buy

      fiat = Inventory.new('usd')

      @washer = WashSale.new(coins, fiat)
    end

    it "taxes after the buy" do
      sales =  [{time: "2013-02-01", amount: 100, price: 0, txid: "A23", link: @buy}]
      sales_records = sales.map{|sale| Statement.new(sale)}
      @washer.tax_check(sales_records, Time.parse("2013-02-02"))
      @washer.taxes.must_equal []
    end

  end
end