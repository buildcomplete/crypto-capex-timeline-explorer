pkg load io % For loading csv file
pkg load image % For 2d with padding
pkg load signal % For using findPeaks
pkg load miscellaneous % For outputting directly to a markdown file
graphics_toolkit('qt'); % Ensure we are using qt renderer

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
coin_plot(dates, pric, 'Unit Price', cmap);


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

figure('name', 'market cap average at different smothin levels');
subplot(2,2,1)
coin_plot(dates, mcap_smooth_w, 'Weekly', cmap, labels);
subplot(2,2,2)
coin_plot(dates, mcap_smooth_m, 'Monthly', cmap);
subplot(2,2,3)
coin_plot(dates, mcap_smooth_q, 'Quarterly', cmap);
subplot(2,2,4)
coin_plot(dates, mcap_smooth_y, 'Yearly', cmap);

figure('name', 'market price average at different smothin levels');
subplot(2,2,1)
coin_plot(dates, pric_smooth_w, 'Weekly', cmap, labels);
subplot(2,2,2)
coin_plot(dates, pric_smooth_m, 'Monthly', cmap);
subplot(2,2,3)
coin_plot(dates, pric_smooth_q, 'Quarterly', cmap);
subplot(2,2,4)
coin_plot(dates, pric_smooth_y, 'Yearly', cmap);


figure
N=[N_m, N_q, N_y];
H={'monthly','quartly','yearly'};
base_set = pric_smooth_w;

plotIdx  = 1:6;
plotIdx = reshape(plotIdx, 2,3);
nPeaks = 5; % Take this number of best opportunities and worst losses and plot
for i=1:3

  G = coin_growth_rate(N(i), base_set);


  %[pksCapMac, locCapMax] = findpeaks(base_set(1,:), 'MinPeakDistance', N_m*2, 'MinPeakHeight', 300);
  [pksCapMac, locCapMax] = findpeaks(max(zeros(1,size(G,2)), -1*G(1,:)), 'MinPeakDistance', N_m*2, 'MinPeakHeight', 0.3);
  [pksGrowth, locGrowth] = findpeaks(max(zeros(1,size(G,2)), G(1,:)), 'MinPeakDistance', N_m*2, 'MinPeakHeight', 0.3);

  % Reduce peaks according to nPeaks
  if (length(pksCapMac) > nPeaks)
    [_, idxPeaks] = sort(pksCapMac, "descend");
    locCapMax = locCapMax(idxPeaks)(1:nPeaks);
  endif

  if (length(pksGrowth) > nPeaks)
    [_, idxPeaks] = sort(pksGrowth, "descend");
    locGrowth = locGrowth(idxPeaks)(1:nPeaks);
  endif


  subplot(3,2,plotIdx(1,i))
  hold on;
  plot(dates(locCapMax), base_set(1,locCapMax), 'r*');
  plot(dates(locGrowth), base_set(1,locGrowth), 'g^');
  coin_plot(dates, base_set(1,:), 'weekly average market price', [cmap(1,:)]);
  legend([[labels{1} ' bottom failures' ]; [labels{1} ' top opportunities' ]; labels{1}], 'Location', 'northwest'); % Add a legend
  ylabels = get(gca, 'yticklabel');
  ylabels_formatted = cellfun(@(x) sprintf('$%dk', str2double(x)/1000), ylabels, 'UniformOutput', false);
  set(gca, 'yticklabel', ylabels_formatted);

  hold off;


  subplot(3,2,plotIdx(2,i))
  hold on;
  plot(dates(locCapMax), G(1,locCapMax), 'r*');
  plot(dates(locGrowth), G(1,locGrowth), 'g^');
  coin_plot(dates, G(1,:), ['growth for ' H{i} ' investment'], [cmap(1,:)]);
  plot([dates(1), dates(end)], [0 0], 'k--')

  ylabels = get(gca, 'yticklabel');
  ylabels_formatted = cellfun(@(x) sprintf('$%d%%', str2double(x)*100), ylabels, 'UniformOutput', false);
  set(gca, 'yticklabel', ylabels_formatted);
  hold off;

  locsOfInterestAI = [locCapMax locGrowth];
  datesOfInterestAI = dates(locsOfInterestAI);
  growthAI = G(1,locsOfInterestAI);
  [_, idx] = sort(locsOfInterestAI);
  datesOfInterestAI = datesOfInterestAI(idx);
  growthAI = growthAI(idx)';
##  save_table(datesOfInterestAI, growthAI, 'growthAI.md', 'Dates of interest (Annual investment)', 'Growth');
end

% Create sumary investment prospects
% CoinX Weekly horizon
% CoinX Monthly horizon
% CoinX Quarterly horizon
% CoinX Yearly horizon

W = coin_growth_rate(N_w, base_set);
M = coin_growth_rate(N_m, base_set);
Q = coin_growth_rate(N_q, base_set);
Y = coin_growth_rate(N_y, base_set);
X = [W; M; Q; Y];

% mark entryes before birth with a distince color

%% Mapping table

segmentation = horizon_segmentation(X);
for i=0:(size(segmentation,1)-1)
  bday = birthdays(1+mod(i,size(birthdays,1)));
  mask = dates < bday;
  segmentation(i+1,mask')=9;
end
figure
imagesc(segmentation, [0 9]);
% imagesc(0:9, [0 10]);

groups = {'week', 'month', 'quarter', 'year'};
bigGroup = {};
for r=1:4;
  for i=1:length(labels)
    bigGroup{length(bigGroup)+1} = [label(i){:}  ' - ' groups{r} ];
  end
end
yticks(1:length(bigGroup))
yticklabels(bigGroup);
hex_colors = hex2rgb(['#DAFF47'; '#EDA200'; '#D24E71'; '#91008D'; '#040404'; '#001889'; '#004616'; '#188B41'; '#74C286'; '#3C3C4C'; ]);
colormap(hex_colors );

xlabels = get(gca, 'xticklabel');
xlabels_formatted = cellfun(@(x)   datestr(dates(str2double(x)), 'yyyy-mm-dd'), xlabels, 'UniformOutput', false);
set(gca, 'xticklabel', xlabels_formatted);


figure
subplot(4,1,1);
imagesc(X > 0);
yticklabels({'week', 'month', 'quarter', 'year'});
title('gain > 0%');

subplot(4,1,2);
XX = (X > 0.1);
imagesc(XX);
yticklabels({'week', 'month', 'quarter', 'year'});
title('gain >10%');

subplot(4,1,3)
imagesc(X>1);
yticklabels({'week', 'month', 'quarter', 'year'});
title('gain >100%');

subplot(4,1,4)
imagesc(X>10);
yticklabels({'week', 'month', 'quarter', 'year'});
title('gain >1000%');

coin_plot(dates, M, 'Weekly growth')

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

