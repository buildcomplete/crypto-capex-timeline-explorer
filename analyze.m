pkg load io
pkg load image
graphics_toolkit('qt');

# Load data
data = csv2cell('cap.csv', ';');
labels = data(2:end,1); % Extract the labels
dates = data(1,2:end); % Extract the dates, skipping the first cell
dates = datenum(dates, 'yyyy-mm-dd'); % Convert the dates
mcap = cell2mat(data(2:end,2:end));

% Create a colormap with 21 unique colors
cmap = colorcube(21);
idx2 = (1:21)';
idx2 = [idx2(1:2:21); flipud(idx2(2:2:21))];
cmap = cmap(idx2,:);
% Create stacked area plot of raw data
f = figure('Name', 'raw');

h = area(dates, mcap', 'LineStyle', 'none'); % Create the stacked area plot
datetick('x', 'yyyy-mm-dd'); % Format the x-axis as dates
legend(labels, 'Location', 'northwest'); % Add a legend
% Apply the colormap to each dataset
for i = 1:21
    set(h(i), 'FaceColor', cmap(i,:));
end
pause(2)
set(f, 'Position', [0, 0, 1024, 800]);

for N = 3:2:11
  for N2 = 1:3
    disp([N N2])
  end
end

% Create stacked area plot of smothed data
N = 3; % Define the number of neighbors to include in the average
figure('Name', 'Smoothed');
##for N2 = 1:3
##  mcap_smooth_temp = smooth2D(mcap, 1, N);
  mcap_smooth = smooth2D(mcap, 1, N);

##  subplot(3,1, N2);
  h=area(dates, mcap_smooth', 'LineStyle', 'none'); % Create the stacked area plot
  datetick('x', 'yyyy-mm-dd'); % Format the x-axis as dates
  legend(labels, 'Location', 'northwest'); % Add a legend
  % Apply the colormap to each dataset
  for i = 1:21
      set(h(i), 'FaceColor', cmap(i,:));
  end
##end

% Create normalized area plot
sum_mcap = sum(mcap, 1); % Calculate the sum of each column
mcap_ratio = bsxfun(@rdivide, mcap, sum_mcap); % Normalize each column by dividing by the column sum
mcap_ratio(isnan(mcap_ratio)) = 0; % Replasce NaN with zero

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

