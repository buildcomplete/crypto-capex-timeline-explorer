# Get dependencies
require 'json'
require_relative "coin_functions" # Load coin functions
require "date"

# Load Coins
coins = JSON.load File.new "coins.json"
ids = coins.map {|coin| coin["id"] }
puts "Coins index loaded"

# Filter data when download has succeded
# Filter coins with no capital value and calculate total capital
market_cap = ids
    .map{ |id|
        (coin_info_valid? id) ? [id, (load_coin_data id)["market_data"]["market_cap"]["usd"]] : [id, 0] }
    .filter{|x|
        ( (!x[1].nil?) and (x[1] > 0)) }
puts "Crap filtered"

market_cap_total = market_cap.inject(0.0) {|tot, x| tot+x[1]}
market_cap.sort_by! {|x| -x[1]}

# Proceed only considering top50 from today 22.Nov 2023
# and calculate percentage of market cap
@market_cap_50 = market_cap[0..49].map {|x| {:id => x[0], :market_cap =>  x[1], :cap_ratio =>  x[1]/market_cap_total} }

# Set ranges for data acqusitions
@start_date = Date.new(2013, 05, 01) # first, first day of month on coin gecko with any valid data
@end_date = Date.new(2023, 12, 16)
@dates = (@start_date..@end_date).step(1)

# Detect first entry of each coin
# Find coin birthday,
# use binary search reducing number of dates to visit from
#  worst case '(end_date-start_date).to_i => 3836' to
#  worst case 'Math.log2(3836)=>11.9' lookups pr coin
@market_cap_50.each { |x|
    find_coin_birthday(x[:id], @start_date, @end_date)
}
puts "Birthdays checked"

### Expand with birthday
# If we did find all birthdays,
# expand the cap50 hashes with the birthday
@market_cap_50.map! { |x|
    x.merge( {:birthday => get_birthday(x[:id])} )
}

# Get coin data pr month for 15 oldest and 15 most valuable coins (21 merged)
@old_or_valuable_coins = (@market_cap_50[0..15] | (@market_cap_50.sort_by {|x| x[:birthday]}[0..15])).sort_by {|x| x[:birthday]}

downloadCompleted = false
until downloadCompleted
    missing_downloads = 0
    @dates.each {|test_date|
        # take old or coins with highest value
        @old_or_valuable_coins.each {|x|
            if (test_date >= x[:birthday] ) then
                if (!download_missing_coin_hist_with_retry(x[:id], test_date, 7)) then
                    missing_downloads = missing_downloads + 1
                end
            end
        }
    }
    downloadCompleted = missing_downloads==0
    puts missing_downloads.to_s + " coins missing to be downloaded"
    if !downloadCompleted then
        sleep 30
    end
end
puts "Download completed"
