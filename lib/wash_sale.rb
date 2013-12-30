require 'csv'
require_relative 'statement'
require_relative 'inventory'
require_relative 'tax'

class WashSale

  attr_reader :inventory, :taxes

  def initialize(inventory)
    @inventory = inventory
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
    raise "Insufficient dollars of #{inventory.dollars.to_f} to buy #{value.to_f}" if inventory.dollars < value
    @inventory << record
    @inventory.dollars -= value
  end

  def sell(record)
    reductions = inventory.remove(record.amount)
    puts "#{reductions.size} reductions to sell off #{record.amount.to_f} coins"
    reductions.map do |reduction|
      duration_seconds = record.time - reduction[:statement].time
      duration_days = duration_seconds/60/60/24
      value = reduction[:reduce] * record.price
      inventory.dollars += value
      puts "Sale amount #{reduction[:reduce].to_f} price #{record.price.to_f}"
      type = duration_days >= 30 ? "ltcg" : "stcg"
      puts "Tax event type: #{type} (#{duration_days.to_i} days) value: #{value.to_f}"
      tax = Tax.new({time: record.time, type: type, value: value})
      @taxes << tax
      tax
    end
  end

  def wash_sale(record)
    case record.action
    when "spent"
      buy(record)
    when "earned"
      sell(record)
    end
  end

end
