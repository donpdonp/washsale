require 'csv'
require_relative 'statement'
require_relative 'inventory'

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
    records = inventory.remove(record.amount)
    duration_seconds = record.time - records[0].time
    puts "sold from #{duration_seconds/60/60/24} days"
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
