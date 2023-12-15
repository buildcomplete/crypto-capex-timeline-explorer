% Testing growth rate function
XXX=[ linspace(1, 10, 10) linspace(10, 1, 10) ]
figure
subplot(2,1,1)
plot(XXX)
subplot(2,1,2)
plot(coin_growth_rate(3, XXX))

% inspecting subset of coin price
coindIdx = 3;
dates_sub = dates(1:365);
mcap_sub = mcap(coindIdx,1:365);
tvol_sub = tvol(coindIdx,1:365);
pric_sub = pric(coindIdx,1:365);
f = figure('name', 'market cap and trade volume');
subplot(3,1,1)
coin_plot(dates_sub, mcap_sub, 'Market Cap', cmap(coindIdx,:));

subplot(3,1,2)
coin_plot(dates_sub, tvol_sub, 'Trade Volume', cmap(coindIdx,:));

subplot(3,1,3)
coin_plot(dates_sub, pric_sub, 'Unit Price', cmap(coindIdx,:));

% Detect strange / invalid data and repair with value from previous coin
for i=1:length(labels)

  badData = find(mcap(i,:)<0);
  while (length(badData) > 0)
    mcap(i, badData) = mcap(i, badData-1);
    badData = find(mcap(i,:)<0);
  end

  badData = find(pric(i,:)<0);
  while (length(badData) > 0)
    pric(i, badData) = pric(i, badData-1);
    badData = find(pric(i,:)<0);
  end
end

plot(dates, mcap(i,:))

