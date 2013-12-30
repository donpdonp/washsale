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
    raise "Insufficient dollars of #{fiat.total.to_f} to buy #{value.to_f}" if fiat.total < value
    coins << Statement.new({time:record.time, amount:record.amount, price: record.price})
    @fiat.remove(value)
  end

  def sell(record)
    reductions = coins.remove(record.amount)
    puts "#{reductions.size} reductions to sell off #{record.amount.to_f} coins"
    reductions.map do |reduction|
      value = reduction[:reduce] * record.price
      puts "Sale amount #{reduction[:reduce].to_f} price #{record.price.to_f} = #{value.to_f}"
      Statement.new({time:record.time, amount:value, price: 1})
    end
  end

  def wash_sale(record)
    case record.action
    when "spent"
      buy(record)
    when "earned"
      reductions = sell(record)
      reductions.each{|r| fiat << r}
      tax_check(reductions, record.time)
      reductions
    end
  end

  def tax_check(balances, time)
    balances.reduce([]) do |taxes, balance|
      duration_seconds = time - balance.time
      duration_days = duration_seconds/60/60/24
      if duration_days > 30
        puts "Tax event LTCG (#{duration_days.to_i} days) value: #{balance.amount.to_f}"
        tax = Tax.new({time: balance.time, type: "ltcg", value: balance.amount})
        taxes << tax
        @taxes << tax
      end
      taxes
    end
  end

end
