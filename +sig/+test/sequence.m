function s = sequence(varargin)
% SIG.TEST.SEQUENCE Creates a sequence signal from an array
%   S = SIG.TEST.SEQUENCE(SEQ, INTERVAL[, DELAY, NAME]) Returns a signal
%   named 'sequence' which updates with the values of `seq` at a frequency
%   of `interval` after a given delay.
%
%   Inputs:
%     seq : An array of values for s to update with.
%     interval : The time interval between updates in seconds.
%     delay : The start delay in seconds.  Default: 2.
%     name : The name of the signal.  Default: 'x'.
%
%   Output:
%     s : The signal whose values will be updated.
%
%   Example:
%     % Create a signal that counts to 5
%     counter = sig.test.sequence(1:5, 1); % Update every second
%     h = output(counter); % print values to the command window
%
% TODO Find a cleaner way of tidying these signals up when out of scope
%
% See also SIG.TEST.CREATE

% Create some variables for storing our network
persistent net schedule nodes n
if isempty(net) % If there's not already a network...
  net = sig.Net; % ...create a new one
  net.Debug = 'on'; % Activate debug mode by default 
end

p = inputParser;
p.addRequired('seq')
p.addRequired('interval', @double)
p.addOptional('delay', 2)
p.addOptional('name', 'x', @ischar)
p.parse(varargin{:})
p = p.Results;

% Keep track of the number of nodes in our network.  When there are no more
% nodes (i.e. the signals have been cleared from the workspace), we will
% stop the schedule timer.  This ensures that the network scheduler is only
% run while there is one or more sequence signals in scope.
if isempty(nodes) % No nodes
  nodes = net.origin('nodes');
  nNodes = nodes.scan(@plus, 0);
  n = then(nNodes < 1, true);
end
update = net.origin('indexer'); % Signal to trigger index changes
seqSig = net.origin('seq'); seqSig.post(p.seq); % Signal to hold the sequence
idx = update.scan(@plus, 0); % Signal to index into our sequence
idx = idx.keepWhen(idx <= length(p.seq)); % Stop when we reach the end
s = seqSig(idx); % Index into our sequence signal
if iscell(p.seq) % unwrap
  s = s.map(@(v) v{:});
end
s.Name = p.name;

% When signal falls out of scope, subtract from total number of nodes
% addlistener(s, 'ObjectBeingDestroyed', @(~,~)nodes.post(-1));
s.Node.Listeners = TidyHandle(@() nodes.post(-1));

% Create a timer for updating the indexer
tmr = timer('Name', 'Sequence timer', ...
  'ExecutionMode', 'fixedRate', ...
  'Period', p.interval, ... % Interval between posts, i.e. the frequency
  'StartDelay', p.delay, ... % Delay before first value
  'TimerFcn', @(~,~)update.post(true),...
  'StopFcn', @(~,~)cleanup);

% If no valid schedule timer exists, create one and store it.  This
% periodically runs the network schedule so that any dependent delay
% signals can update
if isempty(schedule) || ~isvalid(schedule)
  schedule = timer('Name', 'Schedule timer', ...
    'ExecutionMode', 'fixedDelay', ...
    'Period', 0.05, ... % Run at 20Hz
    'TimerFcn', @(~,~)net.runSchedule, ...
    'StopFcn', @(src,~)delete(src)); % Delete itself when finished
  % create listener to stop timer when either net is deleted or there are
  % no longer any nodes in the network
  net.Listeners = n.onValue(@(~)stop(schedule));
end

% If the schedule timer is stopped, start it 
if strcmp(schedule.running, 'off'), start(schedule); end

% Create a signal to stop the sequence timer when the sequence is finished
terminate = at(-1, idx == length(p.seq));
h = terminate.delay(1).onValue(@(~)stop(tmr));
start(tmr) % Start the sequence timer
nodes.post(1); % Move index to first position

  function cleanup()
    % CLEANUP Delete sequence timer when finished
    %  Sequence timer StopFcn callback.  Deletes the timer.
    if isvalid(tmr), delete(tmr); end
    delete(h)
    disp('deleting sequence timer')
  end
end
