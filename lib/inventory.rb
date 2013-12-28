class Inventory
  def initialize(inventory)
    @balances = inventory.map{|i| Statement.new(i)}
  end

  def <<(statement)
    @balances << statement
  end

  def each(&f)
    @balances.each{|b| yield b}
  end

  def map(&f)
    @balances.map{|b| yield b}
  end

  def total_coins
    @balances.reduce(0){|memo, record| memo + record.amount}
  end
end