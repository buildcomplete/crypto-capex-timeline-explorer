# Exploring market cap for different crypto currencies.
This project is for exploring crypto currency market cap as function of time, the main purpose is to identify which coins became influential and investigate why.

This readme was used for prototyping all the code, later functions was moved to [coin_functions.rb](coin_functions.rb)

## Result plots:

![Market cap ratio all coins](plots/market_cap_ratio_all.png)
![Market cap ratio alt coins](plots/market_cap_ratio_alt_coins.png)
![Market cap alt coins](plots/market_cap_alt_coins.png)
Data provided by CoinGecko using [CoinGecko public API ](https://www.coingecko.com/api/documentation)

## Result Discussion
Bitcoin has a very large percentage of the value, and has keept the value for several years, lets start to see what is Bitcoin, then what do the other early coins offer, what problem do the new coin try to solve.

The following table gives an overview of different currencies 
|Currency|Starting date|Vision|White paper|Transaction speed (trx/s)|
|---|---|---|---|---|
|Bitcoin|2009|To create a decentralized zero trust currency that minimzed transaction cost|[bitcoin.pdf](https://bitcoin.org/bitcoin.pdf)|7
|Litecoin|2013-05|A faster and cheaper alternative to bitcoin, lower transaction fee, faster transactions|N/A|56
|Ripple|2013-08|Faster transaction speed by utilizing collectively-trusted subnetworks|[ripple-whitepaper](https://whitepaper.io/document/1/ripple-whitepaper)|1500
|Dogecoin|2013-12|Created as a joke, but it works|[dogecoin Github](https://github.com/dogecoin/dogecoin)|23
|Monero|2014-05|A privacy focused currency, as it turned out previous currencies was only pseudo anonymous-and the owner can in many cases be identifed. Monero wanted to fix that by making the transaction amount, sender and receiver truely anonymous|[cryptonote-whitepaper.pdf](https://www.getmonero.org/resources/research-lab/pubs/cryptonote-whitepaper.pdf)||1700
|Stellar|2014-08|Faster transaction and confirmation speed|[stellar-consensus-protocol](https://stellar.org/learn/stellar-consensus-protocol)|1000
|Tether|2015-03|purpose|wp|tr/s
|Etherium|2015-08|purpose|wp|tr/s
|Bitcoin cash|2017-08|purpose|wp|tr/s
|binancecoin|2017-09|purpose|wp|tr/s
|cardano|2017-10|purpose|wp|tr/s
|tron|2017-11|purpose|wp|tr/s
|chainlink|2017-11|purpose|wp|tr/s
|maker|2017-12|purpose|wp|tr/s
|usd-coin|2018-10|purpose|wp|tr/s
|matic-network|2019-04|purpose|wp|tr/s
|solana|2020-04|purpose|wp|tr/s
|polkadot|2020-08|purpose|wp|tr/s
|avalanche-2|2020-09|purpose|wp|tr/s
|staked-ether|2020-12|purpose|wp|tr/s

### Bitcoin
Bitcoin was the first cryptocurrency that still is successfull, the reasons are probably that it is decentralized


# Generating data.

## Environment setup
All stuff is happening inside a container.
```docker
FROM ruby:latest
WORKDIR /root/gecko
CMD ["tail", "-f", "/dev/null"] 
```

Started with a persistance storage in my host OS
```docker
version: "3.2"
services:
  coinexplorer:
    container_name: coinexplorer
    build: './init/'
    volumes:
      - ./init/root:/root 
```

## Initialize folders...
Create folder for coins, and for historical data
```bash
mkdir coins
mkdir coins/history
mkdir coins/history/birthdays
mkdir assets
```

### Fetching list of all coins from coingecko
```bash
curl -X 'GET' 'https://api.coingecko.com/api/v3/coins/list?include_platform=true' -H 'accept: application/json' >> coins.json
```

### Load Coins
```ruby
require 'json'
coins = JSON.load File.new "coins.json"
ids = coins.map {|coin| coin["id"] }
```

### Get coin info
The market cap from this is used to select coins of interest
```ruby
ids.each { |x|

    # If we do not have the data, try to fetch it, with 5 retrys
    cmd = coin_info_curl_command x
    i=1
    while (!coin_info_valid? x) and i < 6
        puts ("⚙"*i) +": " + x
        system cmd
        sleep 1 + i # Respect coingecko rate limit 30requests / min
        i = i + 1
    end
    
    # If we have valid data for the coin, then proceed
    if  coin_info_valid? x then
        puts "✔ : " + x

}
```
* Notice, all data fecthing stuff was run several times since the rate limit blocked download even though I tried to respect it.

### Filter data when download has succeded
```ruby
# Filter coins with no capital value and calculate total capital
market_cap = ids
    .map{ |id| 
        (coin_info_valid? id) ? [id, (load_coin_data id)["market_data"]["market_cap"]["usd"]] : [id, 0] }
    .filter{|x| 
        ( (!x[1].nil?) and (x[1] > 0)) }

market_cap_total = market_cap.inject(0.0) {|tot, x| tot+x[1]}
market_cap.sort_by! {|x| -x[1]}

# Proceed only considering top50 from today 22.Nov 2023
# and calculate percentage of market cap
market_cap_50 = market_cap[0..49].map {|x| {:id => x[0], :market_cap =>  x[1], :cap_ratio =>  x[1]/market_cap_total} }
```

# Set ranges for data acqusitions
```ruby
require "date"
start_date = Date.new(2013, 05, 01) # first, first day of month on coin gecko with any valid data
end_date = Date.new(2023, 11, 01) # First day of this month (when creating script)

test_date = start_date
dates = [];
while test_date <= end_date
    dates.push(test_date)
    dates.push(test_date + 15)
    test_date = test_date.next_month
end
```
# Detect first entry of each coin
Find coin birthday, use binary search reducing number of dates to visit from worst case '(end_date-start_date).to_i => 3836' to worst case 'Math.log2(3836)=>11.9' lookups pr coin
```ruby
market_cap_50.each { |x|
    find_coin_birthday(x[:id], start_date, end_date)
}
```

### Expand with birthday
If we did find all birthdays, 
expand the cap50 hashes with the birthday
```ruby
market_cap_50.map! { |x|
    x.merge( {:birthday => get_birthday(x[:id])} )
}
```

### Get coin data pr month for 15 oldest and 15 most valuable coins (21 merged)
```ruby
old_or_valuable_coins = (market_cap_50[0..14] | (market_cap_50.sort_by {|x| x[:birthday]}[0..14])).sort_by {|x| x[:birthday]}
dates.each {|test_date|
    # take old or coins with highest value
    old_or_valuable_coins.each {|x| 
        if (test_date >= x[:birthday]  ) then
            download_missing_coin_hist_with_retry(x[:id], test_date, 7)
        end
    }
}
```

### Create CSV file with market cap for each coin
```ruby
File.open("market_cap2.csv", "w") do |file|
  file.puts(dates.inject("Dates ") {|string, date| string + ";" + date.strftime("%Y-%m-%d")})
  old_or_valuable_coins.each {|c|
    file.puts(dates.inject(c[:id]) {|string, date| string + ";" + safe_get_coin_market_cap(c[:id], date).to_s} )
  }
end
```

### Create CSV file with market trade volume for each coin
```ruby
File.open("market_vol.csv", "w") do |file|
  file.puts(dates.inject("Dates ") {|string, date| string + ";" + date.strftime("%Y-%m-%d")})
  old_or_valuable_coins.each {|c|
    file.puts(dates.inject(c[:id]) {|string, date| string + ";" + safe_get_coin_volume(c[:id], date).to_s} )
  }
end
```

### Download thumbs
I consider using them in my plot
```ruby
old_or_valuable_coins.each { |c|
  img = load_coin_data(c[:id])["image"]["thumb"]
  system "curl " + img + " > assets/"+ c[:id] +"_thumb.png"
}
```
