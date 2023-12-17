function Z = horizon_segmentation(X0)

  % lower limit, upper limit, target
  limits = [
    -inf -10 0
    -10 -1 1
    -1 -0.1 2
    -0.1 -0.05 3
    -0.05 0.05 4
    0.05 0.1 5
    0.1 1 6
    1 10 7
    10 +inf 8];

  Z = zeros(size(X0));

  for i=1:(size(limits,1))
    Z( X0 > limits(i,1) & X0 < limits(i,2) )=limits(i,3);
  end
end
