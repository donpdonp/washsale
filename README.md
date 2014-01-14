washsale
========
Calculate USA IRS basis value from mtgox exchange history. Every sale of a capital asset
is taxed based on the purchase price of that asset. This script tracks the buy/sell history
of coins on mtgox, which can quickly exceed the ability of one person to calculate by hand,
and results in an new inventory output - your bitcoin inventory broken out by the basis
or purchase value of each fraction of a coin.

Disclaimer: I am not a lawyer or an accountant of any kind. 
The output of this software is not meant as tax advice. No warranty.
I wrote this for my own needs and disclaim liability for anything
the script does.

Steps
=======

1. Setup the Initial Inventory. 

In my case I have mined coins from 2 years ago. Since they were mined I'm using
a basis of $0. Another option is using the basis of the current market rate at the
time of mining. I went with the 'safest' approach. My inventory.json looks like

```
{"btc":[{"time":"2011-02-01", "amount":2.8092, "price":0, "txid":"mined1"}],
 "usd":[]}
```

2. Retrieve mtgox history. 

In account history on the mtgox website, download the history csv files for USD. Make sure
the csv is the USD version, not the BTC version.

A history file looks like
```
Index,Date,Type,Info,Value,Balance
1,"2013-07-10 14:42:34",earned,"BTC sold: [tid:1373467354XXXXXX] 2.60000007 BTC at $76.97000",202.34181,464.59029
2,"2013-07-10 14:42:34",fee,"BTC sold: [tid:1373467354XXXXXX] 2.60000007 BTC at $76.97000 (0.6% fee)",1.21405,463.37
624

```

3. Run the script

```
$ ruby ./load.rb  mtgox-history.csv

```


Future
======
Intended improvements to this script are to identify long term asset sales, and use the
'wash sale' rule for short term asset sales. Also to support other exchanges, and the
csv history from the bitcoin client itself.
