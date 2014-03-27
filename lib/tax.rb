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
    parts << "Bitcoin"
    parts << "#{@link.link.time.to_date} #{@link.time.to_date}"
    parts << "$#{"%0.2f"%@proceeds}"
    parts << "$#{"%0.2f"%@cost}"
    if link.wash_sale?
    end
    parts << "#{type} $#{"%0.2f"%gainloss} "
    parts.join("\t")
  end
end
