function G = coin_growth_rate(N, gdate)

  % Create filter for subtracting starting from end, notice, octave flips the filter therefore
  F=[1 zeros(1, N-2) -1];

  % calc -start+end = (end-start)
  nominator = conv2(gdate, F, 'valid');

  % Pad right side (end) with zeros as growth is not calculated for future
  nominator = postpad(nominator',size(gdate,2), 0)';
  G = nominator ./ gdate; % Divide by starting value

  % Clean division by zero
  G(isnan(G)) = 0;
  G(isinf(G)) = 0;
end
