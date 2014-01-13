class Inventory
  attr_reader :balances, :code

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

  def clear_empties!
    @balances = @balances.select{|b| b.amount > 0} # clean out empties
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
    if @balances.size > 0
      puts "Inventory #{@code}:"
      @balances.each {|line| puts " "+line.inspect}
      puts "Total #{"%0.2f" % total.to_f}#{@code}"
    else
      puts "Inventory #{@code} is empty."
    end
  end

end