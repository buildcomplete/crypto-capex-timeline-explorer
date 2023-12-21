
data_dtime = csv2cell('dtime.csv', ';');
labels_d = data_dtime(1,2:end); % Extract the labels

dates_1 = datenum(data_dtime(2:end,1), 'yyyy-mm-dd');
c = data_dtime(2:end,2:end);
dates_2 = zeros (size (c)); % initialize a numeric array of the same size as c
for i = 1:numel (c) % loop over each element of c
  try
    dates_2(i) = datenum (c{i}, 'yyyy-mm-dd HH:MM:SS'); % try to convert the element to a date number
  catch
    dates_2(i) = NaN; % if conversion fails, assign NaN
  end
end

plot(dates_2(:,1), dates_1', '.');
minY = min(dates_2(dates_2>0)(:))
maxY = max(dates_2(:))
legend(labels_d(1)', 'Location', 'northwest')

datetick('y', 'yyyy-mm-dd'); % Format the x-axis as dates
ylim( [min(dates_1(:)), max(dates_1(:))])
#datetick('x', 'yyyy-mm-dd', "keepticks", 5, "keeplimits"); % Format the x-axis as dates
datetick('x', 'yyyy-mm-dd'); % Format the x-axis as dates
xlim( [minY maxY]);


delta = conv(sort(dates_2(dates_2>2)(:)), [1 -1], 'valid');
plot(delta, '.')

