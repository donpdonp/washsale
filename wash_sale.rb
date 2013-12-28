require 'csv'
require_relative 'statement'

class WashSale

  def initialize(inventory, sorted_records)
    @records = sorted_records
    @balances = []
  end

  def buys
    @records.select{|r| r.action == "spent"}
  end

  def sells
    @records.select{|r| r.action == "earned"}
  end

  def buy(record)
    @balances << record
  end

  def sell(record)
    @balances.each {}
  end

  def balances_display
    words = @balances.map do |b|
      "#{b.time.strftime("%b-%d")} #{b.amount}@#{b.price} $#{"%0.2f"%b.value.to_f}"
    end
    puts "Inventory:"
    words.each {|line| puts line}
  end

  def wash_sales
    puts "#{buys.size} buys #{sells.size} sells"
    @records.each do |record|
      case record.action
      when "spent"
        puts " buy #{record.amount} @ #{record.price}"
        buy(record)
      when "earned"
        puts "sell #{record.value_display}"
      end
      balances_display
    end
  end

end
