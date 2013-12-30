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
    coins << Statement.new({time:record.time, amount:value, price: 0})
    fiat.remove(record.amount)
  end

  def sell(record)
    reductions = coins.remove(record.amount)
    puts "#{reductions.size} reductions to sell off #{record.amount.to_f} coins"
    reductions.map do |reduction|
      value = reduction[:reduce] * record.price
      fiat << Statement.new({time:record.time, amount:value, price: 0})
      puts "Sale amount #{reduction[:reduce].to_f} price #{record.price.to_f}"
    end
    tax_check(record.time)
  end

  def wash_sale(record)
    case record.action
    when "spent"
      buy(record)
    when "earned"
      sell(record)
    end
  end

  def tax_check(time)
    @fiat.balances.each do |balance|
      duration_seconds = time - balance.time
      duration_days = duration_seconds/60/60/24
      if duration_days > 30
        tax_time(balance, duration_days)
      end
    end
  end

  def tax_time(sale, sale_days)
    type = sale_days >= 30 ? "ltcg" : "stcg"
    puts "Tax event type: #{type} (#{sale_days.to_i} days) value: #{sale.value.to_f}"
    tax = Tax.new({time: sale.time, type: type, value: sale.value})
    @taxes << tax
    tax
  end
end
