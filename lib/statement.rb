require 'time'
require 'bigdecimal'
require 'csv'

class Statement
  attr_reader :time, :txid, :amount, :price, :account_balance, :link
  attr_accessor :action, :reduced, :fee, :fee_balance

  def initialize(values)
    @reduced = @fee = 0
    if values.is_a?(CSV::Row) || values.is_a?(Array)
      load_csv(values)
    elsif values.is_a?(Hash)
      load_json(values)
    else
      raise "unknown values of #{values.class.name}"
    end
  end

  def load_csv(row)
    id = row[0]
    @time = Time.parse(row[1])
    @action = row[2]
    info = row[3]
    detail = info_parse(@action, info)
    if detail
      @amount = detail[:amount]
      @price = detail[:price]
      @txid = detail[:txid]
    end
    if ["fee","deposit","withdraw"].include?(action)
      @amount = BigDecimal.new(row[4])
      @price = 1
    end
    if ["deposit","withdraw"].include?(action)
      if @txid.nil?
        @txid = "#{action}-id"
      end
    end
    @account_balance = BigDecimal.new(row[5])
  end

  def load_json(json)
    @time = json[:time].is_a?(Time) ? json[:time] : Time.parse(json[:time])
    @amount = BigDecimal.new(json[:amount], 8)
    @price = BigDecimal.new(json[:price])
    @fee = BigDecimal.new(json[:fee]) if json[:fee]
    @reduced = json[:reduced] if json[:reduced]
    @txid = json[:txid]
    @link = json[:link]
  end

  def info_parse(action, info)
    case action
    when "earned", "spent"
      buysell_info_parse(info)
    when "fee"
      fee_info_parse(info)
    end
  end

  def buysell_info_parse(info)
    #"BTC sold: [tid:1362024956429632] 1.20000000 BTC at $32.13310"
    info_match = /(\w+) (bought|sold): \[tid:(\d+)\] (\d+\.\d+).(\w+) at \$((\d+,)*\d+\.\d+)/
    matches = info_match.match(info)
    price = matches[6].gsub(',','')
    {currency: matches[1], buysell: matches[2], txid: matches[3],
     amount: BigDecimal.new(matches[4]), price: BigDecimal.new(price)}
  end

  def fee_info_parse(info)
    info_match = /(\w+) (bought|sold): \[tid:(\d+)\]/
    matches = info_match.match(info)
    # ignore "Fees for Bitcoin withdraw to 1dY69kQp8iZkkVEw..."
    if matches
      {txid: matches[3]}
    end
  end

  def value
    reduced_amount * @price
  end

  def reduced_amount
    wa = @amount-@reduced
    raise "Negative reduced amount for #{txid} #{@amount}" if wa < 0
    wa
  end

  def reduced_ratio
    (@amount-@reduced)/@amount
  end

  def reduced_fee
    @fee * reduced_ratio
  end

  def original_value
    @amount * @price
  end

  def ==(s)
    time == s.time && amount == s.amount && price == s.price && reduced == s.reduced
  end

  def value_display
    "%9.4f" % @value.to_f
  end

  def inspect
    parts = []
    if time.year == Time.now.year
      date = time.strftime("%b-%d")
    else
      date = time.strftime("%Y-%b-%d")
    end

    parts << "#{date} #{action}"
    parts << "#{"%0.5f"%amount.to_f} (#{"%0.5f"%reduced.to_f}) @#{"%0.3f"%price.to_f} = #{"%0.3f"%value} orig:#{"%0.3f"%original_value} fee: #{"%0.3f"%fee} ##{txid}"
    parts << " link:#{link.txid}" if link
    parts.join
  end

  def fee_balance
    @fee_balance || @account_balance
  end
end
