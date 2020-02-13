function X = exp(lambda, sz, bounds, adjusted)
% Requires the Statistics And Machine Learning Toolbox
if nargin < 2; sz = [1, 1]; end
if nargin < 3; bounds = [0, Inf]; end
if nargin < 4; adjusted = false; end
assert(bounds(1) < bounds(2), ...
  'signals:rnd:nonMonotonicBounds', 'Bounds must be monotonically increasing')
assert(all(sign(bounds) ~= -1), ...
  'signals:rnd:negativeBounds', 'Bounds must be non-negative')
assert(lambda>0, 'signals:rnd:negativeLambda', 'Lambda must be positive')

if adjusted; lambda = adjustLambda(lambda); end
pLB = expcdf(bounds(1), lambda);
pUB = expcdf(bounds(2), lambda);
r = pLB + (pUB - pLB) .* rand(sz);
X = expinv(r, lambda);

  function l = adjustLambda(lambda)
    l = 1 / fmincon(@(L)((diff(exp(-bounds*L).*(bounds*L+1)/L) / ...
      diff(exp(-bounds*L)))-lambda)^2, 0.5);
  end
end