List possible vs currencies 
```bash
curl -X 'GET' 'https://api.coingecko.com/api/v3/simple/supported_vs_currencies' -H 'accept: application/json' >> supported_vs_currencies.json
```

List Coins
```bash
curl -X 'GET' 'https://api.coingecko.com/api/v3/coins/list?include_platform=true' -H 'accept: application/json' >> coins.json
```

Create folder for coins
```bash
mkdir coins
```

Load Coins
```ruby
require 'json'
coins = JSON.load File.new "coins.json"
ids = coins.map {|coin| coin["id"] }
```

Create coin info request
```ruby
def coin_filename(id)
    "coins/"+id+".json"
end

def coin_info_valid?(id)
    x = coin_filename(id)
    if File.file? x and (File.size x) > 0 then
        begin
            data = JSON.load File.new x
            return (data.has_key? "id" and data["id"] == id)
        rescue
            return false
        end
    end
    return false
end

def load_coin_data(id)
    return JSON.load File.new coin_filename(id)
end

def coin_info_curl_command(id)
    "curl -X 'GET' 'https://api.coingecko.com/api/v3/coins/" + id.sub(" ", "%20") + "?localization=false&tickers=false&market_data=true&community_data=true&developer_data=true&sparkline=false' -H 'accept: application/json' > " + (coin_filename id)
end

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

```

# Filter coins with no capital value and calculate total capital
```ruby
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

Create folder for historical data
```bash
mkdir coins/history
mkdir coins/history/birthdays
```

# download historical data for coins
```ruby
def coin_hist_filename(id, date)
    "coins/history/" + id.sub(" ", "_") + "-"+(date.strftime "%d-%m-%Y") +".json"
end

def get_coin_history_command(id, date)
    "curl -X 'GET' 'https://api.coingecko.com/api/v3/coins/"+ id.sub(" ", "%20") + "/history?date="+(date.strftime "%d-%m-%Y")+"&localization=false' -H 'accept: application/json' > " + (coin_hist_filename(id, date)) 
end

def coin_hist_valid?(id, date)
    x = coin_hist_filename(id, date)
    if File.file? x and (File.size x) > 0 then
        begin
            data = JSON.load File.new x
            return (data.has_key? "id" and data["id"] == id)
        rescue
            return false
        end
    end
    return false
end

def download_missing_coin_hist_with_retry(id, date, num_retries)
    cmd = get_coin_history_command(id, date)
    i=1
    while (!coin_hist_valid?(id, date)) and i < (num_retries+1)
        puts ("⚙"*i) +": " + id
        system cmd
        sleep 1 + i
        i=i+1
    end
    if  coin_hist_valid?(id, date) then
        puts "✔ : " + id + (date.strftime "%d-%m-%Y")
        return true
    end
    return false
end
```

# detect first entry of each coin
Use binary search to find entry of birth reducing number of dates to visit from 'diff.to_i => 3836' to 'Math.log2(diff.to_i)=>11.9' lookups pr coin
```ruby
def get_coin_hist_from_file(id, date)
    return JSON.load File.new coin_hist_filename(id, date)
end

def coin_hist_has_market_cap?(id, date)
    if coin_hist_valid?(id, date) then
       h = get_coin_hist_from_file(id, date)
       return ((h.has_key? "market_data") and (h["market_data"].has_key? "market_cap") and (h["market_data"]["market_cap"].has_key? "usd"))
    end
    return false
end

def coin_birth_day_filename(id)
    "coins/history/birthdays/" + id.sub(" ", "_") + ".json"
end

def find_coin_birth_day(id, start_date, stop_date)
    if (File.file? (coin_birth_day_filename(id))) then
        return true
    end

    actual_date = (start_date + (stop_date - start_date).to_i  / 2)
    puts "Searching for " + id + " - " + (actual_date.strftime "%d-%m-%Y") + " Range: " + (start_date.strftime "%d-%m-%Y") + " " + (stop_date.strftime "%d-%m-%Y")


    if (!download_missing_coin_hist_with_retry(id, actual_date, 7)) then
        puts("Failed fetching data")
        return false
    end

    
    has_market_cap = coin_hist_has_market_cap?(id, actual_date)
    
    # found birth day
    if (has_market_cap and actual_date == start_date) then
        File.write(coin_birth_day_filename(id), actual_date.to_json)
        return true
    end

    #search depleted
    if (!has_market_cap and actual_date == start_date and actual_date != stop_date) then
        return find_coin_birth_day(id, start_date + 1, stop_date)
    end
    
    if has_market_cap then
        return find_coin_birth_day(id, start_date, actual_date)
    else
        return find_coin_birth_day(id, actual_date, stop_date)
    end

    # search according to new boundary
    return false
end

market_cap_50.each { |x|
    id = x[0]
    find_coin_birth_day(id, start_date, stop_date)
}
```
