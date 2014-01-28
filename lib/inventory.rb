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
    @balances.reduce([]) do |balances, balance|
      available_amount = balance.reduced_amount
      if available_amount > 0 && amount > 0
        if available_amount >= amount
          partial_amount = amount
        else
          partial_amount = available_amount
        end
        balance.reduced += partial_amount
        amount -= partial_amount
        balances << {statement: balance, reduce: partial_amount}
      end
      balances
    end
  end

  def total
    @balances.reduce(0){|memo, record| memo + record.reduced_amount - record.fee}
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
      puts "Inventory #{@code}: empty."
    end
  end

  def summary(adjust)
    if @balances.size > 0
      puts "Inventory #{@code}:"
      @balances.each do |bal|
        if bal.value > 0
          puts " "+bal.inspect
        end
      end
      puts "Total #{"%0.2f" % (total+adjust)}#{@code}"
    else
      puts "Inventory #{@code}: empty."
    end
  end
end