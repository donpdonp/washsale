#!/usr/bin/env ruby
require 'bundler/setup'
require 'json'
require 'wash_sale.rb'

puts "Loading #{ARGV}"
inventory_hash = JSON.parse(File.open("inventory.json").read,{symbolize_names: true})

inventory = Inventory.new(inventory_hash)
puts "** Initial Inventory"
inventory.display

records = []
ARGV.each do |filename|
  CSV.foreach(filename, {headers:true}) do |row|
    records << Statement.new(row)
  end
end
records = records.sort_by(&:time)
puts "** #{records.size} records loaded. from #{records.first.time} to #{records.last.time}"

washer = WashSale.new(inventory)
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
  washer.inventory.display
end

puts "** Final inventory"
washer.inventory.display
puts "** Tax events"
washer.taxes.each do |tax|
  puts "Tax #{tax.time} #{tax.type} $#{"%0.2f"%tax.value.to_f}"
end