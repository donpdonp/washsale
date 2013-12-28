require 'csv'
require_relative 'statement'
require_relative 'inventory'

class WashSale

  def initialize(inventory, sorted_records)
    @records = sorted_records
    @inventory = Inventory.new(inventory)
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
    @inventory.each {}
  end

  def inventory_display
    words = @inventory.map do |b|
      if b.time.year == Time.now.year
        date = b.time.strftime("%b-%d")
      else
        date = b.time.strftime("%Y-%b-%d")
      end
      "#{date} #{"%0.2f"%b.amount.to_f}@#{"%0.2f"%b.price.to_f} $#{"%0.2f"%b.value.to_f}"
    end
    puts "Inventory:"
    words.each {|line| puts line}
  end

  def wash_sales
    puts "#{buys.size} buys #{sells.size} sells"
    @records.each do |record|
      case record.action
      when "spent"
        puts " buy #{"%0.2f"%record.amount} @ #{record.price}"
        buy(record)
      when "earned"
        puts "sell #{record.value_display}"
      end
      inventory_display
    end
  end

end
