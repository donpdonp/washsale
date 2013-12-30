require 'time'
require 'bigdecimal'
require 'csv'

class Statement
  attr_reader :time, :action, :value, :balance, :detail

  def initialize(values)
    if values.is_a?(CSV::Row) || values.is_a?(Array)
      load_csv(values)
    elsif values.is_a?(Hash)
      load_json(values)
    else
      raise "unknown values of #{values.class.name}"
    end
  end

  def load_csv(row)
    @id = row[0]
    @time = Time.parse(row[1])
    @action = row[2]
    @info = row[3]
    @detail = info_parse(@action, @info)
    @value = BigDecimal.new(row[4])
    @balance = BigDecimal.new(row[5])
  end

  def load_json(json)
    @time = json[:time].is_a?(Time) ? json[:time] : Time.parse(json[:time])
    @detail = {}
    @detail[:amount] = BigDecimal.new(json[:amount])
    @detail[:price] = BigDecimal.new(json[:price])
  end

  def info_parse(action, info)
    #"BTC sold: [tid:1362024956429632] 1.20000000 BTC at $32.13310"
    case action
    when "earned", "spent"
      earned_info_parse(info)
    end
  end

  def earned_info_parse(info)
    info_match = /(\w+) (bought|sold): \[tid:(\d+)\] (\d+\.\d+).(\w+) at \$((\d+,)?\d+\.\d+)/
    matches = info_match.match(info)
    {currency: matches[1], buysell: matches[2], tid: matches[3],
     amount: BigDecimal.new(matches[4]), price: BigDecimal.new(matches[6])}
  end

  def amount
    @detail[:amount]
  end

  def amount=(new_amount)
    @detail[:amount] = new_amount
  end

  def price
    @detail[:price]
  end

  def ==(s)
    time == s.time && amount == s.amount && price == s.price
  end

  def value_display
    "%9.4f" % @value.to_f
  end
end
