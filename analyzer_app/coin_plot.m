function coin_plot(dates, data, _title, cmap, labels = [], formatYAxis = true)
  h = plot(dates, data'); % Create the stacked area plot
  title(_title);
  datetick('x', 'yyyy-mm-dd'); % Format the x-axis as dates

  % Add labels if specified
  if (size(labels,1) == size(data,1))
    legend(labels, 'Location', 'northwest'); % Add a legend
  end

  % Apply colormap
  for i = 1:size(cmap,1)
    set(h(i), 'Color', cmap(i,:));
  end
  xlim([dates(1) dates(end)]);

  if formatYAxis
    ylabels = get(gca, 'yticklabel');
    ylabels_formatted = cellfun(@(x) sprintf('$%dk', str2double(x)/1000), ylabels, 'UniformOutput', false);
    set(gca, 'yticklabel', ylabels_formatted);
  end
end
