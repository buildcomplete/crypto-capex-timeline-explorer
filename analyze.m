pkg load io % For loading csv file
pkg load image % For 2d with padding
pkg load signal % For using findPeaks
pkg load miscellaneous % For outputting directly to a markdown file
graphics_toolkit('qt'); % Ensure we are using qt renderer

# Load data
data_mcap = csv2cell('cap.csv', ';')';
data_tvol = csv2cell('vol.csv', ';')';
data_price = csv2cell('price.csv', ';')';

labels = data_mcap(2:end,1); % Extract the labels
dates = data_mcap(1,2:end); % Extract the dates, skipping the first cell
dates = datenum(dates, 'yyyy-mm-dd'); % Convert the dates
mcap = cell2mat(data_mcap(2:end,2:end));
tvol = cell2mat(data_tvol(2:end,2:end));
prices = cell2mat(data_price(2:end,2:end));

mcap = zeros(size(data_mcap)-1);
for r=2:size(data_mcap,1)
  for c=2:size(data_mcap,2)
    mcap(r-1,c-1) = cell2mat(data_mcap(r,c));
  end
end

% Create a colormap with 21 unique colors
cmap = colorcube(21);
idx2 = (1:21)';
idx2 = [idx2(1:2:21); flipud(idx2(2:2:21))];
cmap = cmap(idx2,:);

% Plot raw market cap
f = figure('name', 'market cap and trade volume');
subplot(3,1,1)
coin_plot(dates, mcap, 'Market Cap', cmap);

subplot(3,1,2)
coin_plot(dates, tvol, 'Trade Volume', cmap, labels);

subplot(3,1,3)
coin_plot(dates, prices, 'Unit Price', cmap);


% Create stacked area plot of raw data
f = figure('Name', 'raw');
subplot(2,1,1)
coin_area(dates, mcap, 'Market Cap', cmap);

subplot(2,1,2)
coin_area(dates, tvol, 'Trade Volume', cmap, labels);

% Calculate weekly, montly, quarterly and yearly growth
delta = dates(2) - dates(1);
N_w = make_odd(ceil(7 / delta));
N_m = make_odd(ceil(31 / delta));
N_q = make_odd(ceil(90 / delta));
N_y = make_odd(ceil(360 / delta));



mcap_smooth_w = smooth2D(mcap, 1, N_w);
tvol_smooth_w = smooth2D(tvol, 1, N_w);
mcap_smooth_m = smooth2D(mcap, 1, N_m);
tvol_smooth_m = smooth2D(tvol, 1, N_m);
mcap_smooth_q = smooth2D(mcap, 1, N_q);
tvol_smooth_q = smooth2D(tvol, 1, N_q);
mcap_smooth_y = smooth2D(mcap, 1, N_y);
tvol_smooth_y = smooth2D(tvol, 1, N_y);

figure('name', 'market cap average at different smothin levels');
subplot(2,2,1)
coin_plot(dates, mcap_smooth_w, 'Weekly', cmap, labels);
subplot(2,2,2)
coin_plot(dates, mcap_smooth_m, 'Monthly', cmap);
subplot(2,2,3)
coin_plot(dates, mcap_smooth_q, 'Quarterly', cmap);
subplot(2,2,4)
coin_plot(dates, mcap_smooth_y, 'Yearly', cmap);


figure
N=[N_m, N_q, N_y];
H={'monthly','quartly','yearly'};
plotIdx  = 1:6;
plotIdx = reshape(plotIdx, 2,3);
for i=1:3
  G = coin_growth_rate(N(i), mcap_smooth_m);

  subplot(3,2,plotIdx(1,i))
  [pksCapMac, locCapMax] = findpeaks(mcap_smooth_m(1,:), 'MinPeakDistance', 30, 'MinPeakHeight', 300);
  [pksGrowth, locGrowth] = findpeaks(max(zeros(1,size(G,2)), G(1,:)), 'MinPeakDistance', 30, 'MinPeakHeight', 0.3);

  hold on;
  plot(dates(locCapMax), mcap_smooth_m(1,locCapMax), 'r*');
  plot(dates(locGrowth), mcap_smooth_m(1,locGrowth), 'g^');

  coin_plot(dates, mcap_smooth_m(1,:), 'monthly average market cap', [cmap(1,:)], [labels(1) labels(1)]);
  hold off;

  subplot(3,2,plotIdx(2,i))
  hold on;
  plot(dates(locCapMax), G(1,locCapMax), 'r*');
  plot(dates(locGrowth), G(1,locGrowth), 'g^');
  coin_plot(dates, G(1,:), ['growth for ' H{i} ' investment'], [cmap(1,:)]);
  plot([dates(1), dates(end)], [0 0], 'k--')
  hold off;

  locsOfInterestAI = [locCapMax locGrowth];
  datesOfInterestAI = dates(locsOfInterestAI);
  growthAI = G(1,locsOfInterestAI);
  [_, idx] = sort(locsOfInterestAI);
  datesOfInterestAI = datesOfInterestAI(idx);
  growthAI = growthAI(idx)';
##  save_table(datesOfInterestAI, growthAI, 'growthAI.md', 'Dates of interest (Annual investment)', 'Growth');
end

% Create stacked area plot of smothed data
figure('Name', 'Smoothed');

subplot(2,1,1)
coin_area(dates, mcap_smooth_w, 'market cap', cmap, labels);
subplot(2,1,2)
coin_area(dates, mcap_smooth_w, 'market volume', cmap);

% Create normalized area plot
sum_mcap = sum(mcap, 1); % Calculate the sum of each column
mcap_ratio = bsxfun(@rdivide, mcap, sum_mcap); % Normalize each column by dividing by the column sum
mcap_ratio(isnan(mcap_ratio)) = 0; % Replasce NaN with zero

% Spike / change analysis
figure('name', 'spikes/changes');
subplot(3,1,1)
coin_plot(dates, mcap_smooth_m, 'market cap (monthly average)', cmap, labels);
subplot(3,1,2)
spikes = mcap_smooth_m-mcap_smooth_w;
coin_plot(dates, spikes, 'market cap change', cmap, labels);
subplot(3,1,3)
imagesc(spikes)



%%% For normalized data, ordered data so the biggest volume is in the middle
rowSums = sum(mcap_ratio, 2);
[sortedSums, idx] = sort(rowSums);
n = length(idx);
midIdx = [idx(1:2:n); flipud(idx(2:2:n))];
mcap_ratio = mcap_ratio(midIdx, :);
mcap= mcap(midIdx, :);
mcap_smooth = mcap_smooth(midIdx,:);
labels = labels(midIdx,:);
cmap = cmap(midIdx,:);

figure('Name', 'Ratio,');
h = area(dates, mcap_ratio', 'LineStyle', 'none'); % Create the stacked area plot
datetick('x', 'yyyy-mm-dd'); % Format the x-axis as dates
legend(labels, 'Location', 'northwest'); % Add a legend
% Apply the colormap to each dataset
for i = 1:21
    set(h(i), 'FaceColor', cmap(i,:));
end
ylim([0 1])

% Create normalized area plot of smoothed data

sum_mcap_s = sum(mcap_smooth, 1); % Calculate the sum of each column
mcap_ratio_smooth = bsxfun(@rdivide, mcap_smooth, sum_mcap_s); % Normalize each column by dividing by the column sum
mcap_ratio_smooth(isnan(mcap_ratio_smooth)) = 0;
figure('Name', 'Ratio, Smoothed');
h=area(dates, mcap_ratio_smooth', 'LineStyle', 'none'); % Create the stacked area plot
% Apply the colormap to each dataset

datetick('x', 'yyyy-mm-dd'); % Format the x-axis as dates
legend(labels, 'Location', 'northwest'); % Add a legend
for i = 1:21
    set(h(i), 'FaceColor', cmap(i,:));
end
ylim([0 1])

