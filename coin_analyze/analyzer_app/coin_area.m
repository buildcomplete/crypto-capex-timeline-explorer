function coin_area(dates, data, _title, cmap, labels = [])
  h = area(dates, data', 'LineStyle', 'none'); % Create the stacked area plot
  title(_title);
  datetick('x', 'yyyy-mm-dd'); % Format the x-axis as dates

  % Add labels if specified
  if (size(labels,1) == size(data,1))
    legend(labels, 'Location', 'northwest'); % Add a legend
  end

  % Apply colormap
  for i = 1:length(cmap)
    set(h(i), 'FaceColor', cmap(i,:));
  end

  xlim([min(dates) max(dates)]);
end
