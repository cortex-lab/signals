function [init, tFcn, xFcn] = quiescienceWatch
% SIG.SCAN.QUIESCENCEWATCH Return scanning functions for SetEpochTrigger
%   [init, tFcn, xFcn] = quiescienceWatch three function handles that are
%   used by the Signal method setEpochTrigger to update the state of a
%   trigger signal.
%
%   setEpochTrigger logic:
%     Returns a scanning signal that once activated, triggers when 'x' does
%     not change more than some threshold after a specified period. The
%     trigger watch is activated by a new required period arriving in
%     'newPeriod'. 't' should be a time signal to monitor. 'threshold'
%     optionally specifies the maximum amount of change to tolerate before
%     restarting the watch period (if unspecified it defaults to zero).
%     This effectively tests the following:
%       dx/dt < thesh where dt == dur
%
%     The scanning signal's value is a struct with the following fields:
%       win - the length of the time window.
%       remaining - the length of time remaining in window before 'armed'
%         set to false.
%       mvmt - cumulative sum of absolute values of 'dx' within window.
%       armed - initialized to true and false when remaining <= 0.
%
%   Outputs:
%     init (function_handle) - returns the seed state struct
%     tFcn (function_handle) - modifies the state struct w.r.t time
%     xFcn (function_handle) - modifies the state struct w.r.t position
%
%   Example:
%     % Get functions for the scanning signal
%     [initState, tUpdate, xUpdate] = sig.scan.quiescienceWatch;
%     % Each time period updates, return a default state structure
%     newState = period.map(initState);
%     % Update state structure each when t and x signals change
%     state = scan(t.delta(), tUpdate,... scan time increments
%                  x.delta(), xUpdate,... scan x deltas
%                  newState,... initial state on arming trigger
%                  'pars', threshold); % parameters
%     state = state.subscriptable(); % allow field subscripting on state
%
% See also SIG.NODE.SIGNAL/SETEPOCHTRIGGER

% Return functions
init = @initState;
tFcn = @tUpdate;
xFcn = @xUpdate;
end

function state = initState(dur)
% INITSTATE The initial state struct
%   Returns a default structure, used as the seed value of a scanning
%   signal.  
% 
%   Input:
%     dur (double) - the duration of the window within which to monitor
%       changes in 'mvmt' field.  The initial value of the 'win' and
%       'remaining' fields.
%
%   Output:
%     state (struct) - the initial state, with the value of the 'win' and
%       'remaining' fields set to 'dur'.
%
%   Example:
%     seed = period.map(initState);
 state = struct('win', dur, 'remaining', dur, 'mvmt', 0, 'armed', true);
end

function state = tUpdate(state, dt, ~)
% TUPDATE Update trigger state based on a time increment
%   Called by a scanning signal to update the current state based on the
%   amount of time elapsed.  The value of dt is subtracted from the
%   'remaining' field, and if the new value of 'remaining' is 0, 'armed' is
%   set to false.
%
%   Input:
%     state (struct) - the current state structure.
%     dt (double) - the amount of time to subtract from 'remaining' if
%       'armed' field is true.
%
%   Output:
%     state (struct) - the new state structure, with the value of the
%       'remaining' decremented by 'dt' and 'armed' set to false if 'win'
%       passed.
if state.armed % decrement time remaining until quiescent period met
  state.remaining = max(state.remaining - dt, 0); 
  if state.remaining == 0 % time's up, trigger can be released
    state.armed = false; % state is now released
  end
end
end

function state = xUpdate(state, dx, thresh)
% XUPDATE Update trigger state based on position increment
%   Called by a scanning signal to update the current state based on the
%   change in some signal's value.  The absolute value of dx is added to
%   the 'mvmt' field, and if the new value of 'mvmt' is greater than
%   thresh, 'remaining' is set to the value of 'win' and 'mvmt' is reset to
%   0.
%
%   Input:
%     state (struct) - the current state structure.
%     dx (double) - the absolute value to add to 'mvmt' if 'armed' field is
%        true.
%     thresh (double) - the threshold value of 'mvmt' at which to reset the
%       value of 'remaining' to 'win', and the value of 'mvmt' to 0.
%
%   Output:
%     state (struct) - the new state structure, with the value of the
%       'mvmt' incremented by 'dt' and 'armed' set to false if 'win'
%       passed.

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