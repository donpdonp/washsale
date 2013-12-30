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
    @inventory << record
  end

  def sell(record)
    reductions = inventory.remove(record.amount)
    puts "#{reductions.size} reductions to sell off #{record.amount.to_f} coins"
    reductions.map do |reduction|
      duration_seconds = record.time - reduction[:statement].time
      duration_days = duration_seconds/60/60/24
      value = reduction[:reduce] * record.price
      puts "Sale amount #{reduction[:reduce].to_f} price #{record.price.to_f}"
      type = duration_days >= 30 ? "ltcg" : "stcg"
      puts "Tax event time: #{record.time} type: #{type} (#{duration_days.to_i} days) value: #{value.to_f}"
      @taxes << Tax.new({time: record.time, type: type, value: value})
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
