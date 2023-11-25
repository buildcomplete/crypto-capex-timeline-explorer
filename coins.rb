require 'json'

coins = JSON.load File.new "coins.json"
ids = coins.map {|coin| coin["id"] }

def coin_filename(id)
    "coins/"+id.sub(" ", "_")+".json"
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
