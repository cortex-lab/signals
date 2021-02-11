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
  
  properties (SetAccess = protected)
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
      % ENTRYADDED Log new entry
      %   This method is called once when a new field is added via
      %   subscripted assignment and creates a logging signal.  This is
      %   called by the StructRef subsasgn method.
      %
      %   Inputs:
      %     name (char) - The name of the newly assigned field
      %     value (sig.Signal) - The Signal assigned to the field
      %
      % See also STRUCTREF/SUBSASGN
      
      % all event entries should be signals, so let's turn them into
      % logging signals
      id = 'signals:sig:Registry:typeError';
      assert(isa(value, 'sig.Signal'), id, 'must assign Signals only');
%       fprintf('Signal %s registered\n', name);
      this.EntryLogs.(name) = value.log(this.ClockFun);
    end
    
    function s = logs(this, clockOffset)
      % Returns a structure of logged signal values and times
      %  If a clockOffset is provided, all timestampes are returned with
      %  respect to that reference time.
      %
      %  Input:
      %    clockOffset (float) - A reference timestamp.  All log times
      %     will be returned relative to this.  Default: 0.
      %
      %  Example:
      %    t0 = @now; % Reference time
      %    events = sig.Registry(@now); % Create our registy
      %    events.a = A^2;       % Log a signal
      %    events.b = A.lag(1);  % Log another signal
      %    [...]                 % Update signals with values
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

