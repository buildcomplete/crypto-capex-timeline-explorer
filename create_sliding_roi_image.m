% Create ROI image with incremental plan
for coindIdx = 1:length(labels)
    base_set = pric_smooth_w(coindIdx,:);
    R = zeros(1080-1,length(base_set));
    for N=2:1080 % two days to 3 years horizon
      G = coin_growth_rate(N, base_set);
      R(N-1,:) = G;
    end

    F = (R>0).*1 + (R>1).*0.1 + (R>5).*0.05;
    %F = horizon_segmentation(R);
    bday = birthdays(coindIdx);
    mask = dates < bday;
    F(:,mask')=-0.2;
    for d=2:size(F,1)
    F(d,(end-d):end)= -0.1;
    end
    imagesc(F)
    set(gcf, 'Units', 'pixels', 'Position', [0, 0, 550, 600])
    ##hex_colors = hex2rgb(['#DAFF47'; '#EDA200'; '#D24E71'; '#91008D'; '#040404'; '#001889'; '#004616'; '#188B41'; '#74C286'; '#3C3C4C'; ]);
    ##colormap(hex_colors );
    xlabels = get(gca, 'xticklabel');
    xlabels_formatted = cellfun(@(x)   datestr(dates(str2double(x)), 'yyyy-mm-dd'), xlabels, 'UniformOutput', false);
    set(gca, 'xticklabel', xlabels_formatted);
    title([labels(coindIdx)' " ROI according to investment length in days"])
    ylabel("Investment length in days");
    xlabel("Day of investment");
    print(sprintf("sliding_roi/sr_%d_%s.png", coindIdx, labels{coindIdx}), '-dpng')
end
