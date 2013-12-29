require 'csv'
require_relative 'statement'
require_relative 'inventory'

class WashSale

  attr_reader :inventory

  def initialize(inventory)
    @inventory = inventory
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
    if record.value > inventory.total
      raise "Error, insufficient inventory for #{record}"
    end
  end

  def wash_sale(record)
    case record.action
    when "spent"
      puts " buy #{"%0.2f"%record.amount} @ #{"%0.2f"%record.price}"
      buy(record)
    when "earned"
      puts "sell #{record.value_display}"
    end
  end

end
