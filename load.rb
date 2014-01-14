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

#records = records.sort_by(&:time)
puts "** #{records.size} records loaded. from #{records.first.time.to_date} to #{records.last.time.to_date}"

washer = WashSale.new(coins, fiat)
fee_total = 0
deposit_total = 0
withdraw_total = 0
records.each do |record|
  processable = false
  case record.action
  when "spent"
    processable = true
    puts "= buy #{record.time.strftime("%Y-%m-%d")} #{"%0.2f"%record.amount} @ #{"%0.2f"%record.price} = #{"%0.2f"%record.value} ##{record.txid}"
  when "earned"
    processable = true
    puts "=sell #{record.time.strftime("%Y-%m-%d")} #{"%0.2f"%record.amount}#{coins.code} @ #{"%0.2f"%record.price}#{fiat.code} = #{"%0.2f"%record.value} ##{record.txid}"
  when "fee"
    puts "=fee #{record.time.strftime("%Y-%m-%d")} #{"%0.2f"%record.amount}#{fiat.code} ##{record.txid}"
    fee_total += record.amount
  when "deposit"
    deposit_total += record.amount
    puts "=deposit #{record.time.strftime("%Y-%m-%d")} #{"%0.2f"%record.amount}#{fiat.code} to date: #{"%0.2f"%deposit_total}"
  when "withdraw"
    withdraw_total += record.amount
    puts "=withdraw #{record.time.strftime("%Y-%m-%d")} #{"%0.2f"%record.amount}#{fiat.code} to date: #{"%0.2f"%withdraw_total}"
  else
    puts "=#{record.action} skip"
  end

  if processable
    washer.wash_sale(record)
    calc_error = (record.account_balance - (fiat.total-fee_total) - (deposit_total-withdraw_total)).abs
    puts "!! calculation error csv balance #{"%0.2f"%record.account_balance} - (#{"%0.2f"%fiat.total}-#{"%0.2f"%fee_total}) =  #{"%0.8f"%calc_error}"
    coins.display
    fiat.display
  end
end

puts "** end of records"
puts "Fees $#{"%0.3f"%fee_total} Deposits #{"%0.3f"%deposit_total} Withdraw total #{"%0.3f"%withdraw_total}"
puts "Final USD Balance $#{"%0.3f"%(fiat.total - fee_total)}"
puts "** Tax events"
washer.taxes.each {|tax| puts tax.inspect}