function duration = sample(time)
% TIMESAMPLER Sample a time from some distribution
%  If time is a single value, duration is that value.  If time = [min max],
%  then duration is sampled uniformally.  If time = [min, max, time const],
%  then duration is sampled from a exponential distribution, giving a flat
%  hazard rate.  If numel(time) > 3, duration is a randomly sampled value
%  from time.
%
% See also exp.TimeSampler
  if nargin == 0; duration = 0; return; end
  switch length(time)
    case 3 % A time sampled with a flat hazard function
      r = -time(3) * log(rand); % exprnd
      duration = time(1) + r;
      duration = iff(duration > time(2), time(2), duration);
    case 2 % A time sampled from a uniform distribution
      duration = time(1) + (time(2) - time(1))*rand;
    case 1 % A fixed time
      duration = time(1);
    otherwise % Pick on of the values
      duration = time(randi(numel(time))); % randsample
  end
end