#!/usr/bin/env ruby
require 'bundler/setup'
require 'json'
require 'wash_sale.rb'

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
puts "** #{records.size} records loaded. from #{records.first.time} to #{records.last.time}"

washer = WashSale.new(coins, fiat)
records.each do |record|
  case record.action
  when "spent"
    puts "= buy #{"%0.2f"%record.amount} @ #{"%0.2f"%record.price}"
  when "earned"
    puts "=sell #{"%0.2f"%record.amount} @ #{"%0.2f"%record.price}"
  else
    puts "=#{record.action} skip"
  end

  washer.wash_sale(record)
  washer.coins.display
  washer.fiat.display
end

puts "** Final inventory"
washer.coins.display
washer.fiat.display
puts "** Tax events"
washer.taxes.each do |tax|
  puts "Tax #{tax.time} #{tax.type} $#{"%0.2f"%tax.value.to_f}"
end