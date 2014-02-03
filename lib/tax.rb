class Tax
  attr_reader :time, :proceeds, :link, :gainloss, :cost
  attr_accessor :duration, :type

  def initialize(attrs)
    @time = attrs[:time].is_a?(Time) ? attrs[:time] : Time.parse(attrs[:time])
    @type = attrs[:type]
    @proceeds = attrs[:proceeds]
    @gainloss = attrs[:gainloss]
    @cost = attrs[:cost]
    @duration = attrs[:duration]
    @link = attrs[:link]
  end

  def ==(tix)
    @time == tix.time && @type == tix.type && @proceeds == tix.proceeds
  end

  def inspect
    parts = []
    parts << "Tax event"
    parts << "Buy #{@link.link.time.to_date} @$#{"%0.2f"%@link.link.price}"
    parts << "Sell #{@link.time.to_date} #{"%0.2f"%link.sell_amount}@$#{"%0.2f"%link.sell_price} = $#{"%0.2f"%@proceeds}"
    parts << "(#{duration.to_i} days)"
    if duration < 30 && gainloss < 0
      parts << "WASH SALE"
    end
    parts << "#{type} Gainloss: $#{"%0.2f"%gainloss} "
    parts.join(' ')
  end
end