classdef Registry < StructRef
  %SIG.REGISTRY Log values of Signals assigned to this
  %   Signals added to the Registry object via subassign have their values
  %   stored and timestamped using the provided clock function.  
  %
  %   Example:
  %     clock = hw.ptb.Clock;
  %     registry = sig.Registry(@clock.now)
  %     registry.A = s1;
  %     registry.B = s2;
  %     S = registry.logs()
  %
  % See also AUDSTREAM.REGISTRY, STRUCTREF
  
  properties
    EntryLogs
    ClockFun
  end
  
  methods
    function obj = Registry(clockFun)
      if nargin < 1
        obj.ClockFun = @GetSecs;
      else
        obj.ClockFun = clockFun;
      end
    end

    function value = entryAdded(this, name, value)
      % all event entries should be signals, so let's turn them into
      % logging signals
      assert(isa(value, 'sig.Signal'));
%       fprintf('Signal %s registered\n', name);
      this.EntryLogs.(name) = value.log(this.ClockFun);
    end
    
    function s = logs(this, clockOffset)
      % Returns a structure of logged signal values and times
      %  If a clockOffset is provided, all timestampes are returned with
      %  respect to that reference time.
      %  Example:
      %    net = sig.Net; % Create our network
      %    t0 = now; % e.g. the experiment start
      %    events = sig.Registry(@now); % Create our registy
      %    simpleSignal = net.origin('simpleSignal'); % Create a simple signal to log
      %    events.signalA = simpleSignal^2; % Log a signal
      %    events.signalB = simpleSignal.lag(1); % Log another signal
      %    simpleSignal.post(3) % Post some values to the input signal
      %    simpleSignal.post(4)
      %    simpleSignal.post(8)
      %    s = logs(events, t0); % Return our logged signals as a structure
      if nargin == 1; clockOffset = 0; end
      s = struct;
      evtsfields = fieldnames(this);
      for ii = 1:numel(evtsfields)
        eventname = evtsfields{ii};
        loggedSig = this.EntryLogs.(eventname);
        log = loggedSig.Node.CurrValue;
        s.([eventname 'Values']) = [log.value];
        s.([eventname 'Times']) = [log.time] - clockOffset;
      end
    end
  end
  
end

