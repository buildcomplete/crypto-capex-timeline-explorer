% Detect strange / invalid data and repair with value from previous measurement,
% strange data is defined as ',0'
% the data will be replaced with earlier entries (n-1) until no bad data remains
function Y = coin_fix_invalid_values(X)

  Y = X;
  for i=1:size(X, 1)
    badData = find(Y(i,:)<0);
    while (length(badData) > 0)
      Y(i, badData) = Y(i, badData-1);
      badData = find(Y(i,:)<0);
    end
  end
end
