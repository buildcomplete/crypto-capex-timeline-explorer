require 'sinatra'
require 'haml'

set :bind, '0.0.0.0'
set :port, 5000
set :public_folder, '/shared/'

coins = File.read("/shared/birthdays.csv").split("\n").map { |x| x.split(";")}.drop(1)
coins.map! { |x| {:id=>x[0], :birthday=>x[1]}}
get '/' do
  folder_path = "/shared/area/"
  filenames = []
  Dir.foreach(folder_path) do |filename|
    if filename.end_with?(".jpg") || filename.end_with?(".png")
      filenames << filename
    end
  end
  filenames.join("<br>")
end

get '/blob' do
  haml :blob_page, :format => :html5, locals: { coins: coins }
end

get '/blob2' do
  haml '%div.title Hello World', :path => 'examples/file.haml', :line => 3
end
