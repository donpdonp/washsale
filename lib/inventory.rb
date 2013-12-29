class Inventory
  attr_reader :balances

  def initialize(inventory)
    @balances = inventory.map{|i| Statement.new(i)}
  end

  def <<(statement)
    @balances << statement
  end

  def sufficient_coins?(amount)
    total_coins >= amount
  end

  def remove(amount)
    raise "Insufficient inventory of #{total_coins} to remove #{amount}" unless sufficient_coins?(amount)
    @balances.select do |balance|
      if balance.amount >= amount
        balance.amount -= amount
      end
    end
  end

  def total_coins
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
    puts "Inventory:"
    words.each {|line| puts line}
    puts "Total coins: #{"%0.2f" % total_coins.to_f}"
  end

end