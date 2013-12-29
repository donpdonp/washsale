#!/usr/bin/env ruby
require 'bundler/setup'
require 'json'
require 'wash_sale.rb'

puts "Loading #{ARGV}"
inventory_hash = JSON.load(File.open("inventory.json"))
inventory = Inventory.new(inventory_hash)
puts "Inventory #{inventory.inspect}"

records = []
ARGV.each do |filename|
  CSV.foreach(filename, {headers:true}) do |row|
    records << Statement.new(row)
  end
end
records = records.sort_by(&:time)
puts "#{records.size} records loaded. from #{records.first.time} to #{records.last.time}"

washer = WashSale.new(inventory)
records.each do |record|
  washer.wash_sale(record)
  washer.inventory.display
end
