base_set = pric_smooth_w;

plotIdx  = 1:6;
plotIdx = reshape(plotIdx, 2,3);

nPeaks = 4; % Take this number of best opportunities and worst losses and plot
for coindIdx=1:length(labels)
    figure
    set(gcf, 'Units', 'pixels', 'Position', [0, 0, 1000, 600])
    N=[N_m, N_q, N_y];
    H={'month','quarter','year'};
    
    % I do not want to plot data before half a month after the coin was born
    noGrowthBeforeValid = sum(dates < birthdays(coindIdx)); 
    for i=1:3
        G = [zeros(1,noGrowthBeforeValid) coin_growth_rate(N(i), base_set(coindIdx,(noGrowthBeforeValid+1):end))];
        
        [pksLoss, locLoss] = findpeaks(max(zeros(1,size(G,2)), -1*G), 'MinPeakDistance', N(i)/2, 'MinPeakHeight', 0.3);
        [pksGrowth, locGrowth] = findpeaks(max(zeros(1,size(G,2)), G), 'MinPeakDistance', N(i)/2, 'MinPeakHeight', 0.3);

        % Reduce peaks according to nPeaks
        if (length(pksLoss) > nPeaks)
            [_, idxPeaks] = sort(pksLoss, "descend");
            locLoss = locLoss(idxPeaks)(1:nPeaks);
        endif

        if (length(pksGrowth) > nPeaks)
            [_, idxPeaks] = sort(pksGrowth, "descend");
            locGrowth = locGrowth(idxPeaks)(1:nPeaks);
        endif

        subplot(3,2,plotIdx(1,i))
        hold on;
        plot(dates(locLoss), base_set(coindIdx,locLoss), 'r*');
        plot(dates(locGrowth), base_set(coindIdx,locGrowth), 'g^');

        % Create line segments for growth
        yStepAnots = (max(base_set(coindIdx,:)) - min(base_set(coindIdx,:))) * 0.05;
        cc = 1;
        for p = locGrowth
            plot([dates(p) dates(p+N(i)-1)], [base_set(coindIdx,p) base_set(coindIdx,p+N(i)-1)] , 'g--');
            text(dates(p)+10, base_set(coindIdx,p)+yStepAnots, sprintf('%d',cc), "color", 'g');
            cc = cc+1;
        endfor

        % Create for loss
        for p = locLoss
            plot([dates(p) dates(p+N(i)-1)], [base_set(coindIdx,p) base_set(coindIdx,p+N(i)-1)] , 'r--');
            text(dates(p)-10, base_set(coindIdx,p)-yStepAnots, sprintf('%d',cc), "color", 'r');
            cc = cc+1;
        endfor

        coin_plot(dates, base_set(coindIdx,:), sprintf('%s weekly average market price', labels{coindIdx}) , [0 0 0], [], false);
        legend([[labels{coindIdx} ' bottom failures' ]; [labels{1} ' top opportunities' ]; labels{coindIdx}], 'Location', 'northwest'); % Add a legend
        ylabels = get(gca, 'yticklabel');
        ylabels_formatted = cellfun(@(x) sprintf('$%dk', str2double(x)/1000), ylabels, 'UniformOutput', false);
        set(gca, 'yticklabel', ylabels_formatted);

        hold off;

        subplot(3,2,plotIdx(2,i))
        hold on;
        plot(dates(locLoss), G(1,locLoss), 'r*');
        plot(dates(locGrowth), G(1,locGrowth), 'g^');
        coin_plot(dates, G, sprintf('%s ROI for one %s investment', labels{coindIdx}, H{i}), [0 0 0], [],false);
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
    print(sprintf("/shared/fixed_roi/fr_WMQY_%s.png", labels{coindIdx}), '-dpng')
end
