class Inventory
  attr_reader :balances

  def initialize(code)
    @code = code
    @balances = []
  end

  def <<(statement)
    if statement.is_a?(Hash)
      statement = Statement.new(statement)
    end
    @balances << statement
  end

  def sufficient_coins?(amount)
    total_coins >= amount
  end

  def remove(amount)
    raise "Insufficient inventory of #{total_coins} to remove #{amount}" unless sufficient_coins?(amount)
    reductions = @balances.reduce([]) do |balances, balance|
      if amount > 0
        if balance.amount >= amount
          partial_amount = amount
          balance.amount -= amount
        else
          partial_amount = balance.amount
          balance.amount = 0
        end
        balances << {statement: balance, reduce: partial_amount}
      end
    end
    @balances = @balances.select{|b| b.amount > 0} # clean out empties
    reductions
  end

  def total
    @balances.reduce(0){|memo, record| memo + record.amount}
  end

  def ==(inv)
    return false if inv.balances.size != balances.size
    return false if inv.dollars != @dollars
    rejects = false
    @balances.each_with_index do |balance, idx|
      rejects = true unless balance == inv.balances[idx]
    end
    !rejects
  end

  def display
    words = @balances.map do |b|
      if b.time.year == Time.now.year
        date = b.time.strftime("%b-%d")
      else
        date = b.time.strftime("%Y-%b-%d")
      end
      "#{date} #{"%0.2f"%b.amount.to_f}@#{"%0.2f"%b.price.to_f} $#{"%0.2f"%b.value.to_f}"
    end
    puts "Inventory:"
    words.each {|line| puts line}
    puts "Total #{"%0.2f" % total_coins.to_f} #{code}"
  end

end