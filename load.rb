#!/usr/bin/env ruby
require 'bundler/setup'
require 'json'
require_relative 'lib/wash_sale.rb'

puts "Loading #{ARGV}"
inventory_hash = JSON.parse(File.open("inventory.json").read,{symbolize_names: true})

coins, fiat = inventory_hash.map do |code, records|
  inv = Inventory.new(code)
  records.each {|h| inv << h}
  inv
end
puts "** Initial Inventory"
coins.display
fiat.display

records = []
ARGV.each do |filename|
  CSV.foreach(filename, {headers:true}) do |row|
    records << Statement.new(row)
  end
end

records = records.sort_by(&:time)
puts "** #{records.size} records loaded. from #{records.first.time.to_date} to #{records.last.time.to_date}"

washer = WashSale.new(coins, fiat)
records.each do |record|
  case record.action
  when "spent"
    puts "= buy #{record.time.strftime("%Y-%m-%d")} #{"%0.2f"%record.amount} @ #{"%0.2f"%record.price} = #{"%0.2f"%record.value} ##{record.txid}"
  when "earned"
    puts "=sell #{record.time.strftime("%Y-%m-%d")} #{"%0.2f"%record.amount}#{coins.code} @ #{"%0.2f"%record.price}#{fiat.code} = #{"%0.2f"%record.value} ##{record.txid}"
  else
    puts "=#{record.action} skip"
  end

  washer.wash_sale(record)
  coins.display
  fiat.display
end

puts "** Final inventory"
washer.coins.display
washer.fiat.display
puts "** Tax events"
washer.taxes.each {|tax| puts tax.inspect}