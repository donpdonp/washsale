require 'csv'
require_relative 'statement'
require_relative 'inventory'
require_relative 'tax'

class WashSale

  attr_reader :coins, :fiat, :taxes

  def initialize(coins, fiat)
    @coins = coins
    @fiat = fiat
    @taxes = []
  end

  def buys
    @records.select{|r| r.action == "spent"}
  end

  def sells
    @records.select{|r| r.action == "earned"}
  end

  def buy(record)
    value = record.amount * record.price
    raise "Insufficient dollars of #{"%0.2f"%fiat.total.to_f} to buy #{"%0.2f"%value.to_f}" if fiat.total < value
    coins << Statement.new({time:record.time, amount:record.amount, price: record.price,
                            txid: record.txid, fee: record.fee})
    @fiat.remove(value)
  end

  def sell(record)
    reductions = coins.remove(record.amount)
    puts "#{reductions.size} reductions to sell off #{record.amount.to_f} coins"
    reductions.map do |reduction|
      value = reduction[:reduce] * record.price
      fee = reduction[:reduce]/record.amount*record.fee
      puts " Sale: #{"%0.4f"%reduction[:reduce].to_f} @ #{"%0.4f"%record.price.to_f} = #{"%8.4f"%value.to_f} fee #{"%0.3f"%fee} From tx ##{reduction[:statement].txid} #{reduction[:statement].time.strftime("%Y-%m-%d")}"
      Statement.new({time:record.time, amount:value, price: 1,
                     txid: record.txid, link: reduction[:statement],
                     fee: fee})
    end
  end

  def wash_sale(record)
    case record.action
    when "spent"
      buy(record)
      fiat.clear_empties!
    when "earned"
      reductions = sell(record)
      reductions.each{|r| fiat << r}
      #tax_check(reductions, record.time)
      reductions
    end
  end

  def tax_check(balances, time)
    balances.reduce([]) do |taxes, balance|
      duration_seconds = time - balance.link.time
      duration_days = duration_seconds/60/60/24
      proceeds = balance.value - balance.link.value
      tax = Tax.new({time: balance.time, duration: duration_days, value: proceeds, link: balance})
      if duration_days > 365
        # Long term sale
        tax.type = "ltcg"
        taxes << tax
        @taxes << tax
        puts " "+tax.inspect
      else
        # Short term sale
        tax.type = "stcg"
        taxes << tax
        @taxes << tax
        puts " "+tax.inspect
      end
      taxes
    end
  end

end
