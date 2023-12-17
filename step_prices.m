for coindIdx = 1:length(labels)
    figure('name', 'market price average at different smothin levels');
    set(gcf, 'Units', 'pixels', 'Position', [0, 0, 1000, 600])
    
    subplot(2,2,1)
    coin_plot(dates, pric_smooth_w(coindIdx,:), 'Weekly', [0 0 0]);
    
    subplot(2,2,2)
    coin_plot(dates, pric_smooth_m(coindIdx,:), 'Monthly',  [0 0 0]);
    
    subplot(2,2,3)
    coin_plot(dates, pric_smooth_q(coindIdx,:), 'Quarterly',  [0 0 0]);
    subplot(2,2,4)
    coin_plot(dates, pric_smooth_y(coindIdx,:), 'Yearly', [0 0 0]);
    
    title([labels(coindIdx)' " price yearly average"])
    print(sprintf("shared/simple/price_%d_%s.png", coindIdx, labels{coindIdx}), '-dpng')
end
