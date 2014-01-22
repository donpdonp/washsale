#!/usr/bin/env ruby
require 'bundler/setup'
require 'json'
require_relative 'lib/wash_sale.rb'

if ARGV.size != 2
  puts "usage: load.rb mtgox_usd.csv mtgox_btc.csv"
  exit
end

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

CSV.foreach(ARGV[0], {headers:true}) do |row|
  stmt = Statement.new(row)
  # usd fee backfill
  if stmt.action == 'fee'
    matching_record = records.select{|r| r.txid == stmt.txid}.first
    matching_record.fee = stmt.amount
    matching_record.fee_balance = stmt.account_balance
  end
  records << stmt
end

# btc fee backfill
CSV.foreach(ARGV[1], {headers:true}) do |row|
  stmt = Statement.new(row)
  if stmt.action == 'fee'
    records.each_with_index do |r, idx|
      if r.txid == stmt.txid
        r.fee = stmt.amount * r.price
        r.fee_balance = stmt.account_balance * r.price
        records.insert(idx, stmt)
        break
      end
    end
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
    puts "=sell #{record.time.strftime("%Y-%m-%d")} #{"%0.2f"%record.amount}#{coins.code} @ #{"%0.2f"%record.price}#{fiat.code} = #{"%0.2f"%record.value} ##{record.txid} #{"%0.3f"%record.fee}"
  when "fee"
    puts "=fee #{record.time.strftime("%Y-%m-%d")} #{"%0.2f"%record.amount}#{fiat.code} ##{record.txid}"
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
    calc_error = (record.fee_balance - fiat.total - (deposit_total-withdraw_total)).abs
    puts "!! calculation error csv balance #{"%0.2f"%record.fee_balance} - #{"%0.2f"%fiat.total} = #{"%0.8f"%calc_error}"
    puts "** coins total: #{record.time.strftime("%Y-%m-%d %H:%M:%S")} #{"%0.4f"%coins.total}"
    puts "** fiat total: #{record.time.strftime("%Y-%m-%d %H:%M:%S")} #{"%0.4f"%fiat.total}"
    #coins.display
    #fiat.display
  end
end

puts "** end of records"

coins.summary

puts "Fees $#{"%0.3f"%fee_total} Deposits #{"%0.3f"%deposit_total} Withdraw total #{"%0.3f"%withdraw_total}"
balance = (fiat.total - fee_total)
final_error = (balance - records.last.account_balance).abs
puts "Final USD Balance $#{"%0.3f"%balance}. Error amount: $#{"%0.2f"%final_error}"

puts "** Tax events"
washer.taxes.each {|tax| puts tax.inspect}
