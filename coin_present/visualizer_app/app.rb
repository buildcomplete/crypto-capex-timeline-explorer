require 'sinatra'
require 'haml'

set :bind, '0.0.0.0'
set :port, 5000
set :public_folder, '/shared/'

coins = File.read("/shared/birthdays.csv").split("\n").map { |x| x.split(";")}.drop(1)
coins.map! { |x| {
  :id=>x[0],
  :birthday=>x[1],
  :priceImg=> "/simple/price_"+x[0]+".png",
  :fixedRoiImg => "/fixed_roi/fr_WMQY_"+x[0]+".png",
  :slidingRoiImg => "/sliding_roi/sr_"+x[0]+".png"}
}

get '/' do
  haml :landing_page, :format => :html5, locals: { coins: coins }
end

get '/coin' do
  haml :coin_page, :format => :html5, locals: { coins: coins }
end
