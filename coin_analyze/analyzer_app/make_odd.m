% Enforce a number is even,
% as I prefer symetrical filters to know where data is anchored after convolution.
% Created using Bing chat
% Prompt: After a division in octave, i would like to enforce a number being odd by adding one if it is even
function x = make_odd (n)
  % n is the number to be enforced as odd
  % x is the output number that is odd
  if mod (n, 2) == 0
    % n is even, so add one
    x = n + 1;
  else
    % n is odd, so do nothing
    x = n;
  end
end
