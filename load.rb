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
  if stmt.action == "earned"
    stmt.fee_balance = stmt.account_balance
  end
  # usd fee backfill
  if stmt.action == 'fee'
    matching_record = records.select{|r| r.txid == stmt.txid}.first
    matching_record.fee = stmt.amount
    matching_record.fee_balance = stmt.account_balance
  end
  records << stmt
end

# btc fee backfill
last_btc_idx = nil
CSV.foreach(ARGV[1], {headers:true}) do |row|
  stmt = Statement.new(row)
  if stmt.action == 'in'
    records.each_with_index do |r, idx|
      if r.txid == stmt.txid
        r.fee_balance = stmt.account_balance
        break
      end
    end
  end

  if stmt.action == 'fee'
    records.each_with_index do |r, idx|
      if r.txid == stmt.txid
        r.fee = stmt.amount
        r.fee_balance = stmt.account_balance
        records.insert(idx+1, stmt)
        break
      end
    end
  end

  if ["in","out","fee"].include?(stmt.action)
    records.each_with_index do |r, idx|
      if r.txid == stmt.txid
        last_btc_idx = idx
      end
    end
  end

  if stmt.action == 'withdraw'
    stmt.action = "withdraw_btc"
    records.insert(last_btc_idx+1, stmt)
  end
end

puts "** #{records.size} records loaded. from #{records.first.time.to_date} to #{records.last.time.to_date}"

washer = WashSale.new(coins, fiat)
deposit_total = 0
withdraw_total = 0
deposit_btc_total = 0
withdraw_btc_total = 0
records.each do |record|
  processable = false
  case record.action
  when "spent"
    processable = true
    puts "= buy #{record.time.strftime("%Y-%m-%d")} #{"%0.3f"%record.amount} @ #{"%0.2f"%record.price} = #{"%0.2f"%record.value} fee #{"%0.3f"%record.fee}btc ##{record.txid}"
  when "earned"
    processable = true
    puts "=sell #{record.time.strftime("%Y-%m-%d")} #{"%0.3f"%record.amount}#{coins.code} @ #{"%0.2f"%record.price}#{fiat.code} = #{"%0.2f"%record.value} fee #{"%0.3f"%record.fee}usd ##{record.txid}"
  when "fee"
    puts "=fee #{record.time.strftime("%Y-%m-%d")} #{"%0.3f"%record.amount} ##{record.txid}"
  when "deposit_btc"
    puts "=deposit_btc #{"%0.4f"%record.amount} fee #{"%0.4f"%record.fee} "
    deposit_btc_total += record.amount - record.fee
  when "deposit"
    deposit_total += record.amount
    puts "=deposit #{record.time.strftime("%Y-%m-%d")} #{"%0.2f"%record.amount}#{fiat.code} to date: #{"%0.2f"%deposit_total}"
  when "withdraw_btc"
    puts "=withdraw_btc #{"%0.4f"%record.amount} fee #{"%0.4f"%record.fee} "
    withdraw_btc_total += record.amount + record.fee
  when "withdraw"
    withdraw_total += record.amount
    puts "=withdraw #{record.time.strftime("%Y-%m-%d")} #{"%0.2f"%record.amount}#{fiat.code} to date: #{"%0.2f"%withdraw_total}"
    puts "** coins total: #{record.time.strftime("%Y-%m-%d %H:%M:%S")} #{"%0.4f"%coins.total}"
    puts "** fiat total: #{record.time.strftime("%Y-%m-%d %H:%M:%S")} #{"%0.4f"%(fiat.total+(deposit_total-withdraw_total))}"
  else
    puts "=#{record.action} skip"
  end

  if processable
    washer.wash_sale(record)
    btc_adjust = deposit_btc_total - withdraw_btc_total
    usd_adjust = deposit_total - withdraw_total
    if record.action == "earned"
      if record.fee_balance.nil?
        puts "NIL fee #{record.txid}"
      end
      calc_error = (record.fee_balance - (fiat.total + usd_adjust)).abs
      puts "!! sell calculation error csv fee USD balance #{"%0.2f"%record.fee_balance} - #{"%0.2f"%fiat.total} + #{"%0.2f"%deposit_total} - #{"%0.2f"%withdraw_total} = #{"%0.8f"%calc_error}"
    end
    if record.action == "spent"
      calc_error = (record.fee_balance - (coins.total + btc_adjust)).abs
      puts "!! buy calculation error csv fee BTC balance #{"%0.4f"%record.fee_balance} - #{"%0.4f"%coins.total} + #{"%0.4f"%deposit_btc_total} - #{"%0.4f"%withdraw_btc_total} = #{"%0.8f"%calc_error}"
    end
    puts "** coins total: #{record.time.strftime("%Y-%m-%d %H:%M:%S")} #{"%0.4f"%(coins.total+btc_adjust)}"
    puts "** fiat total: #{record.time.strftime("%Y-%m-%d %H:%M:%S")} #{"%0.4f"%(fiat.total+usd_adjust)}"
  end
end

puts "** end of records"

btc_adjust = deposit_btc_total - withdraw_btc_total
coins.summary(btc_adjust)
usd_adjust = deposit_total - withdraw_total
fiat.summary(usd_adjust)

puts "Deposits #{"%0.3f"%deposit_total}. Withdrawls #{"%0.3f"%withdraw_total}. Difference #{"%0.3f"%(deposit_total-withdraw_total)}"
last_potent = records.select{|r|["fee","earned","spent"].include?(r.action)}.last
final_error = (fiat.total - last_potent.account_balance + usd_adjust).abs
puts "USD Error based on last csv record ##{last_potent.txid}: $#{"%0.2f"%final_error}"

puts "** Tax events"
washer.taxes.each {|tax| puts tax.inspect}
