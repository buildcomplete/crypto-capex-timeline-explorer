pkg load io % For loading csv file
pkg load image % For 2d with padding
pkg load signal % For using findPeaks
% pkg load miscellaneous % For outputting directly to a markdown file
% graphics_toolkit('qt'); % Ensure we are using qt renderer

# Load data
data_mcap = csv2cell('cap.csv', ';')';
data_tvol = csv2cell('vol.csv', ';')';
data_price = csv2cell('price.csv', ';')';
data_birthdays = csv2cell('birthdays.csv', ';')';
labels = data_mcap(2:end,1); % Extract the labels
birthdays = datenum(data_birthdays(2:end,2), 'yyyy-mm-dd'); % Extract birthdays
dates = data_mcap(1,2:end); % Extract the dates, skipping the first cell
dates = datenum(dates, 'yyyy-mm-dd'); % Convert the dates
mcap = cell2mat(data_mcap(2:end,2:end));
tvol = cell2mat(data_tvol(2:end,2:end));
pric = cell2mat(data_price(2:end,2:end));

% Cleanup data
% from before a coins birthday
% and bad data inside dataset (<0)
for i = 1:length(birthdays)
  mask = dates < birthdays(i);
  mcap(i,mask) = 0;
  tvol(i,mask) = 0;
  pric(i,mask) = 0;
end
mcap = coin_fix_invalid_values(mcap);
pric = coin_fix_invalid_values(pric);
tvol = coin_fix_invalid_values(tvol);


% Calculate weekly, montly, quarterly and yearly growth
delta = dates(2) - dates(1);
N_w = make_odd(ceil(7 / delta));
N_m = make_odd(ceil(31 / delta));
N_q = make_odd(ceil(90 / delta));
N_y = make_odd(ceil(360 / delta));
N_by = make_odd(ceil(2*360 / delta));

mcap_smooth_w = smooth2D(mcap, 1, N_w);
tvol_smooth_w = smooth2D(tvol, 1, N_w);
pric_smooth_w = smooth2D(pric, 1, N_w);

mcap_smooth_m = smooth2D(mcap, 1, N_m);
tvol_smooth_m = smooth2D(tvol, 1, N_m);
pric_smooth_m = smooth2D(pric, 1, N_m);

mcap_smooth_q = smooth2D(mcap, 1, N_q);
tvol_smooth_q = smooth2D(tvol, 1, N_q);
pric_smooth_q = smooth2D(pric, 1, N_q);

mcap_smooth_y = smooth2D(mcap, 1, N_y);
tvol_smooth_y = smooth2D(tvol, 1, N_y);
pric_smooth_y = smooth2D(pric, 1, N_y);

mcap_smooth_by = smooth2D(mcap, 1, N_by);
tvol_smooth_by = smooth2D(tvol, 1, N_by);
pric_smooth_by = smooth2D(pric, 1, N_by);