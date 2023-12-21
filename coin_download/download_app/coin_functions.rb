require "date"
require 'json'

def coin_filename(id)
  "/coin_data/coins/"+id.sub(" ", "_")+".json"
end

def coin_hist_filename(id, date)
  "/coin_data/coins/history/" + id.sub(" ", "_") + "-"+(date.strftime "%d-%m-%Y") +".json"
end

def coin_birth_day_filename(id)
  "/coin_data/coins/history/birthdays/" + id.sub(" ", "_") + ".json"
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

def get_coin_history_command(id, date)
  "curl -X 'GET' 'https://api.coingecko.com/api/v3/coins/"+ id.sub(" ", "%20") + "/history?date="+(date.strftime "%d-%m-%Y")+"&localization=false' -H 'accept: application/json' > " + (coin_hist_filename(id, date))
end

# Adding a nasty side effect to coin_hist_valid
# The function now also creates a cache that get_coin_hist_from_file will rely on

$global_coin_hist_cache = {}
def coin_hist_valid?(id, date)
  x = coin_hist_filename(id, date)
  if $global_coin_hist_cache.has_key? x then
    return  true
  end
  if File.file? x and (File.size x) > 0 then
      begin
          data = JSON.load File.new x
          if (data.has_key? "id" and data["id"] == id) then
            $global_coin_hist_cache[x] = data;
            return true
          end
      rescue
        return false

      end
  end
  return false
end

def get_coin_hist_from_file(id, date)
  return (coin_hist_valid?(id, date) ?
    $global_coin_hist_cache[coin_hist_filename(id, date)]
    : nil )
end

def download_missing_coin_hist_with_retry(id, date, num_retries)
  cmd = get_coin_history_command(id, date)
  i=1
  while (!coin_hist_valid?(id, date)) and i < (num_retries+1)
      puts ("⚙"*i) + ": " + id + " " + (date.strftime "%d-%m-%Y")
      system cmd
      sleep 2 + i
      i=i+1
  end
  if  coin_hist_valid?(id, date) then
      puts "✔ : " + id + " " + (date.strftime "%d-%m-%Y")
      return true
  end
  return false
end


def coin_hist_has_market_cap?(id, date)
  if coin_hist_valid?(id, date) then
     h = get_coin_hist_from_file(id, date)
     return ((h.has_key? "market_data") and (h["market_data"].has_key? "market_cap") and (h["market_data"]["market_cap"].has_key? "usd"))
  end
  return false
end

def safe_get_coin_market_cap(id, date)
  if (date < get_birthday(id))
    return 0
  end

  if coin_hist_has_market_cap?(id, date) then
    x = (get_coin_hist_from_file(id, date)["market_data"]["market_cap"]["usd"])
    if x != nil
      return x
    end
  end
  return -1
end

def safe_get_coin_download_time(id, date)
  if coin_hist_has_market_cap?(id, date) then
    x = ((File.ctime coin_hist_filename(id, date)).strftime "%Y-%m-%d %H:%M:%S")
    if x != nil
      return x
    end
  end
  return "0"
end

def safe_get_coin_price(id, date)
  if (date < get_birthday(id))
    return 0
  end

  if coin_hist_has_market_cap?(id, date) then
    return (get_coin_hist_from_file(id, date)["market_data"]["current_price"]["usd"])
  end
  return -1
end

def safe_get_coin_volume(id, date)
  if (date < get_birthday(id))
    return 0
  end

  if coin_hist_has_market_cap?(id, date) then
    return (get_coin_hist_from_file(id, date)["market_data"]["total_volume"]["usd"])
  end
  return -1
end




def save_birthday(id, date)
  File.write(coin_birth_day_filename(id), date.to_json)
end

def get_birthday(id)
  Date.parse JSON.load File.new coin_birth_day_filename(id)
end

# find and save date of when a coin have market cap
# The algorithm using binary search to reduce amount of lookups
def find_coin_birthday(id, start_date, stop_date)
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
    save_birthday(id, actual_date)
      return true
  end

  # special condition due to round down logic, if not we  get stuck at border when start_date+1==stop_date.
  if (!has_market_cap and actual_date == start_date and actual_date != stop_date) then
      return find_coin_birthday(id, start_date + 1, stop_date)
  end

  # search according to new boundary
  if has_market_cap then # found then lowe rregion
      return find_coin_birthday(id, start_date, actual_date)
  else # not found, upper region
      return find_coin_birthday(id, actual_date, stop_date)
  end

  return false
end
