function qevt = quiescenceWatch(newPeriod, t, x, threshold)
%SIG.QUIESCENCEWATCH Trigger when a signal doesn't change for some period
%   qevt = sig.quiescenceWatch(newPeriod, t, x, [threshold]) returns a
%   signal that once activated, triggers when 'x' does not change more than
%   some threshold after a specified period. The trigger watch is activated
%   by a new required period arriving in 'newPeriod'. 't' should be a time
%   signal to monitor. 'threshold' optionally specifies the maximum amount
%   of change to tolerate before restarting the watch period (if
%   unspecified it defaults to zero).
%
% NB: Differences between this and setEpochTrigger: threshold default is 1
% vs 0; first value is true

if nargin < 4
  threshold = 1;
end

newState = newPeriod.map(@initState);  

state = scan(t.delta(), @tUpdate,... scan time increments
  x.delta(), @xUpdate,... scan x deltas
  newState,... initial state on arming trigger
  'pars', threshold); % parameters
state = state.subscriptable(); % allow field subscribting on state
% event signal is derived by monitoring the 'armed' field of state for new
% false values (i.e. when the armed trigger is released).
qevt = state.armed.skipRepeats().not().then(true);

end
%% helper functions
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