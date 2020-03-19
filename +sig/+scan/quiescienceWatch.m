function [init, tFcn, xFcn] = quiescienceWatch
% SIG.SCAN.QUIESCENCEWATCH 
 init = @initState;
 tFcn = @tUpdate;
 xFcn = @xUpdate;
end

function state = initState(dur)
 state = struct('win', dur, 'remaining', dur, 'mvmt', 0, 'armed', true);
end

function state = tUpdate(state, dt, ~)
% update trigger state based on a time increment
if state.armed % decrement time remaining until quiescent period met
  state.remaining = max(state.remaining - dt, 0); 
  if state.remaining == 0 % time's up, trigger can be released
    state.armed = false; % state is now released
  end
end
end

function state = xUpdate(state, dx, thresh)
% update trigger state based on a delta in the signal that must stay below
% threshold
if state.armed
  state.mvmt = state.mvmt + abs(dx); % accumulate the delta
  if state.mvmt > thresh % reached threshold, so reset
    state.mvmt = 0;
    state.remaining = state.win;
  end
end
end