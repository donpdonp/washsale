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