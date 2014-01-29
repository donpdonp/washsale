class Tax
  attr_reader :time, :value, :link
  attr_accessor :duration, :type

  def initialize(attrs)
    @time = attrs[:time].is_a?(Time) ? attrs[:time] : Time.parse(attrs[:time])
    @type = attrs[:type]
    @value = attrs[:value]
    @duration = attrs[:duration]
    @link = attrs[:link]
  end

  def ==(tix)
    @time == tix.time && @type == tix.type && @value == tix.value
  end

  def inspect
    "Tax event Buy #{@link.link.time.to_date} @$#{"%0.2f"%@link.link.price} Sell #{@link.time.to_date} $#{"%0.2f"%@link.amount} (#{duration.to_i} days) #{type} Proceeds: $#{"%0.2f"%value.to_f} "
  end
end