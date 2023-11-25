# Exploring market cap for different crypto currencies.
This project is for exploring crypto currency market cap as function of time, the main purpose is to identify which coins became influential and investigate why.

This readmy was used for prototyping all the code, later function was var moved to [coin_methods.rb](coin_methods.rb)

Create folder for coins, and for historical data
```bash
mkdir coins
mkdir coins/history
mkdir coins/history/birthdays
```

Fetching list of all coins from coingecko
```bash
curl -X 'GET' 'https://api.coingecko.com/api/v3/coins/list?include_platform=true' -H 'accept: application/json' >> coins.json
```

Load Coins
```ruby
require 'json'
coins = JSON.load File.new "coins.json"
ids = coins.map {|coin| coin["id"] }
```

Create coin info request
```ruby
ids.each { |x|

    # If we have valid data for the coin, then proceed
    if  coin_info_valid? x then
        puts "✔ : " + x

    # If we did not have the data, try to fetch it, with 5 retrys
    else
        cmd = coin_info_curl_command x
        i=1
        while (!coin_info_valid? x) and i < 6
            puts ("⚙"*i) +": " + x
            system cmd
            sleep 1 + i
            i=i+1
        end
    end
}

# Filter coins with no capital value and calculate total capital
market_cap = ids
    .map{ |id| 
        (coin_info_valid? id) ? [id, (load_coin_data id)["market_data"]["market_cap"]["usd"]] : [id, 0] }
    .filter{|x| 
        ( (!x[1].nil?) and (x[1] > 0)) }

market_cap_total = market_cap.inject(0.0) {|tot, x| tot+x[1]}
market_cap.sort_by! {|x| -x[1]}
```

# Proceed only considering top50 from today 22.Nov 2023
Also calculate percentage of market cap now
```ruby
market_cap_50 = market_cap[0..49].map {|x| [x[0], x[1], x[1]/market_cap_total] }
```

# Get coin value for each day, given target resolution, using NN sampling
```ruby
require "date"
start_date = Date.new(2013, 05, 01) # first, first day of month on coin gecko with any valid data
end_date = Date.new(2023, 11, 01) # First day of this month (when creating script)
num_days = (end_date - start_date).to_i
width = 1900.0
step = num_days / width # Step in days, ruby works amazing adding numbers as days respecting remainders as fraction of days
 
#start_date.strftime "%d-%m-%Y"
```


# download historical data for coins


# detect first entry of each coin
Use binary search to find entry of birth reducing number of dates to visit from worst case 'diff.to_i => 3836' to worst case 'Math.log2(diff.to_i)=>11.9' lookups pr coin
```ruby

market_cap_50.each { |x|
    id = x[0]
    find_coin_birth_day(id, start_date, stop_date)
}
```
