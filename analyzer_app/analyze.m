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


figure('name', 'market cap average at different smothin levels');
set(gcf, 'Units', 'pixels', 'Position', [0, 0, 1000, 600])
subplot(2,2,1)
coin_plot(dates, mcap_smooth_w, 'Weekly', viridis(21), labels);
subplot(2,2,2)
coin_plot(dates, mcap_smooth_m, 'Monthly', viridis(21));
subplot(2,2,3)
coin_plot(dates, mcap_smooth_q, 'Quarterly', viridis(21));
subplot(2,2,4)
coin_plot(dates, mcap_smooth_y, 'Yearly', viridis(21));
print("shared/simple/cap_all.png", '-dpng')

figure('name', 'market price average at different smothin levels');
set(gcf, 'Units', 'pixels', 'Position', [0, 0, 1000, 600])
subplot(2,2,1)
coin_plot(dates, pric_smooth_w, 'Weekly', viridis(21), labels);
subplot(2,2,2)
coin_plot(dates, pric_smooth_m, 'Monthly', viridis(21));
subplot(2,2,3)
coin_plot(dates, pric_smooth_q, 'Quarterly', viridis(21));
subplot(2,2,4)
coin_plot(dates, pric_smooth_y, 'Yearly', viridis(21));
print("shared/simple/price_all.png", '-dpng')

figure
N=[N_m, N_q, N_y];
H={'monthly','quarterly','yearly'};
base_set = pric_smooth_w;

plotIdx  = 1:8;
plotIdx = reshape(plotIdx, 2,4);
nPeaks = 4; % Take this number of best opportunities and worst losses and plot
for i=1:4

  G = coin_growth_rate(N(i), base_set);
  [pksLoss, locLoss] = findpeaks(max(zeros(1,size(G,2)), -1*G(1,:)), 'MinPeakDistance', N(i)/3, 'MinPeakHeight', 0.3);
  [pksGrowth, locGrowth] = findpeaks(max(zeros(1,size(G,2)), G(1,:)), 'MinPeakDistance', N(i)/3, 'MinPeakHeight', 0.3);

  % Reduce peaks according to nPeaks
  if (length(pksLoss) > nPeaks)
    [_, idxPeaks] = sort(pksLoss, "descend");
    locLoss = locLoss(idxPeaks)(1:nPeaks);
  endif

  if (length(pksGrowth) > nPeaks)
    [_, idxPeaks] = sort(pksGrowth, "descend");
    locGrowth = locGrowth(idxPeaks)(1:nPeaks);
  endif

  subplot(4,2,plotIdx(1,i))
  hold on;
  plot(dates(locLoss), base_set(1,locLoss), 'r*');
  plot(dates(locGrowth), base_set(1,locGrowth), 'g^');

  % Create line segments for growth
  cc = 1;
  for p = locGrowth
   plot([dates(p) dates(p+N(i))], [base_set(1,p) base_set(1,p+N(i))] , 'g--');
   text(dates(p)+100, base_set(1,p)-100, sprintf('%d',cc), "color", 'g');
   cc = cc+1;
  endfor

  % Create for loss
  for p = locLoss
   plot([dates(p) dates(p+N(i))], [base_set(1,p) base_set(1,p+N(i))] , 'r--');
   text(dates(p)-100, base_set(1,p)+100, sprintf('%d',cc), "color", 'r');
   cc = cc+1;
  endfor


  coin_plot(dates, base_set(1,:), 'weekly average market price', [cmap(1,:)]);
  legend([[labels{1} ' bottom failures' ]; [labels{1} ' top opportunities' ]; labels{1}], 'Location', 'northwest'); % Add a legend
  ylabels = get(gca, 'yticklabel');
  ylabels_formatted = cellfun(@(x) sprintf('$%dk', str2double(x)/1000), ylabels, 'UniformOutput', false);
  set(gca, 'yticklabel', ylabels_formatted);

  hold off;

  subplot(4,2,plotIdx(2,i))
  hold on;
  plot(dates(locLoss), G(1,locLoss), 'r*');
  plot(dates(locGrowth), G(1,locGrowth), 'g^');
  coin_plot(dates, G(1,:), ['ROI for ' H{i} ' investment'], [cmap(1,:)]);
  plot([dates(1), dates(end)], [0 0], 'k--')

  ylabels = get(gca, 'yticklabel');
  ylabels_formatted = cellfun(@(x) sprintf('$%d%%', str2double(x)*100), ylabels, 'UniformOutput', false);
  set(gca, 'yticklabel', ylabels_formatted);
  hold off;

  locsOfInterestAI = [locLoss locGrowth];
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

