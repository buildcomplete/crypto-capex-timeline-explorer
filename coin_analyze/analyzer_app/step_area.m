% Create stacked area plot of smothed data
figure;

subplot(3,1,1)
coin_area(dates, mcap_smooth_w, 'Market Cap', cmap, labels);
ylabels = get(gca, 'yticklabel');
ylabels_formatted = cellfun(@(x) sprintf('$%dT', str2double(x)/1e12), ylabels, 'UniformOutput', false);

set(gca, 'yticklabel', ylabels_formatted);

subplot(3,1,2)
coin_area(dates, pric_smooth_w, 'Price', cmap);
ylabels = get(gca, 'yticklabel');
ylabels_formatted = cellfun(@(x) sprintf('$%dk', str2double(x)/1e3), ylabels, 'UniformOutput', false);
set(gca, 'yticklabel', ylabels_formatted);


subplot(3,1,3)
coin_area(dates, tvol_smooth_w, 'Trade Volume', cmap);
ylabels = get(gca, 'yticklabel');
ylabels_formatted = cellfun(@(x) sprintf('$%dB', str2double(x)/1e9), ylabels, 'UniformOutput', false);
set(gca, 'yticklabel', ylabels_formatted);

set(gcf, 'Units', 'pixels', 'Position', [0, 0, 800, 800])
print("/shared/area/mcap_tvol_price_week.png", '-dpng')

close


% Create normalized area plot
sum_mcap = sum(mcap_smooth_w, 1); % Calculate the sum of each column
mcap_ratio = bsxfun(@rdivide, mcap_smooth_w, sum_mcap); % Normalize each column by dividing by the column sum
mcap_ratio(isnan(mcap_ratio)) = 0; % Replasce NaN with zero

% Create normalized area plot of smoothed data
sum_mcap_s = sum(mcap_smooth_w, 1); % Calculate the sum of each column
mcap_ratio_smooth = bsxfun(@rdivide, mcap_smooth_w, sum_mcap_s); % Normalize each column by dividing by the column sum
mcap_ratio_smooth(isnan(mcap_ratio_smooth)) = 0;

figure;
set(gcf, 'Units', 'pixels', 'Position', [0, 0, 800, 500])
coin_area(dates, mcap_ratio, 'market cap ratio', cmap)
ylim([0 1])
print("/shared/area/mcap_ratio.png", '-dpng')

close