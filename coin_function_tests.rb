# This file contains test and experiment more related to ruby than to the actual coin logic
require "date"
require 'json'
require_relative "coin_functions" # Load coin functions
start_date = Date.new(2013, 5, 1) # first, first day of month on coin gecko with any valid data
c = get_coin_hist_from_file("bitcoin", start_date)
