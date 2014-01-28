class Tax
  attr_reader :time, :value
  attr_accessor :duration, :type

  def initialize(attrs)
    @time = attrs[:time].is_a?(Time) ? attrs[:time] : Time.parse(attrs[:time])
    @type = attrs[:type]
    @value = attrs[:value]
    @duration = attrs[:duration]
  end

  def ==(tix)
    @time == tix.time && @type == tix.type && @value == tix.value
  end

  def inspect
    "Tax event #{time.to_date} (#{duration.to_i} days) #{type} Proceeds: $#{"%0.2f"%value.to_f}"
  end
end