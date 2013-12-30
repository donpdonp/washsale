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

  def sufficient?(amount)
    total >= amount
  end

  def remove(amount)
    raise "Insufficient inventory of #{total}#{@code} to remove #{amount}" unless sufficient?(amount)
    reductions = @balances.reduce([]) do |balances, balance|
      if balance.amount >= amount
        partial_amount = amount
        balance.amount -= amount
      else
        partial_amount = balance.amount
        balance.amount = 0
      end
      amount -= partial_amount
      balances << {statement: balance, reduce: partial_amount}
    end
    @balances = @balances.select{|b| b.amount > 0} # clean out empties
    reductions
  end

  def total
    @balances.reduce(0){|memo, record| memo + record.amount}
  end

  def ==(inv)
    return false if inv.balances.size != balances.size
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
    puts "Inventory #{@code}:"
    words.each {|line| puts line}
    puts "Total #{"%0.2f" % total.to_f}#{@code}"
  end

end