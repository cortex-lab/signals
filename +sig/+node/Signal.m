classdef Signal < sig.Signal & handle
  % sig.node.Signal Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (Dependent)
    Name
  end
  
  properties (Hidden, SetAccess = immutable)
    Node
  end
  
  properties (SetAccess = private, Transient)
    % Map of callback functions to execute when value updates
    OnValueCallbacks
    % Unique key of next callback in OnValueCallbacks map
    NextCallbackId = 0
    Listeners
  end
  
  methods
    function this = Signal(node)
      this.Node = node;
      this.OnValueCallbacks = containers.Map('KeyType', 'int32', 'ValueType', 'any');
      % Debugging registry
      if node.Net.Debug
        stack = dbstack('-completenames');
        % TODO Need more robust way of searching stack
        defIdx = find(strcmp({stack.name},'fileFunction/call')) - 1;
        ln = iff(isempty(defIdx), 0, @() stack(defIdx).line);
        node.Net.NodeLine(node.Id) = ln;
      end
    end
    
    function v = get.Name(this)
      v = this.Node.Name;
    end
    
    function set.Name(this, v)
      this.Node.Name = v;
    end
    
    function s = subscriptable(this)
      node = sig.node.Node(this.Node, 'sig.transfer.identity');
      s = sig.node.SubscriptableSignal(node);
      node.FormatSpec = this.Node.FormatSpec;
      node.DisplayInputs = this.Node.DisplayInputs;
      if node.Net.Debug; node.Net.NodeName(node.Id) = this.Name; end
    end
    
    function s = at(what, when)
      s = applyTransferFun(what, when, 'sig.transfer.at', [], '%s.at(%s)');
    end
    
    function s = then(when, what)
      s = applyTransferFun(what, when, 'sig.transfer.at', [], '%s.then(%s)');
      s.Node.DisplayInputs = fliplr(s.Node.DisplayInputs);
      if s.Node.Net.Debug; s.Node.Net.NodeName(s.Node.Id) = s.Name; end
    end
    
    function f = keepWhen(what, when)
      f = applyTransferFun(what, when, 'sig.transfer.keepWhen', [], '%s.keepWhen(%s)');
    end
    
    function m = map(this, f, formatSpec)
      if nargin < 3; formatSpec = sprintf('%%s.map(%s)', toStr(f)); end
      if isa(f, 'sig.Signal')
        m = this.map(true).then(f);
        m.Node.DisplayInputs = this.Node;
        m.Node.FormatSpec = formatSpec;
        % Add string name if in debug mode
        net = this.Node.Net;
        if net.Debug; net.NodeName(m.Node.Id) = m.Name; end
        return
      elseif ~isa(f, 'function_handle')
        f = fun.always(f); % always map to a value
      end
      m = applyTransferFun(this, 'sig.transfer.map', f, formatSpec);
    end
    
    function m = map2(sig1, sig2, f, varargin)
      m = mapn(sig1, sig2, f, varargin{:});
    end
    
    function varargout = mapn(varargin)
      % destructure varargin
      if isa(varargin{end}, 'function_handle')
        [sigs{1:nargin-1}, f] = varargin{:};
        formatSpec = sprintf(['mapn(' repmat('%%s, ', 1, numel(sigs)) '%s)'], toStr(f));
      else
        [sigs{1:nargin-2}, f, formatSpec] = varargin{:};
      end
      % Deal with formatSpec of multiple output args
      if nargout > 1 && (ischar(formatSpec) || numel(formatSpec) == 1)
        formatSpec = strcat(formatSpec, [{''}, strcat('[',num2cellstr(2:nargout), ']')]);
      end
      varargout = cell(1,nargout);
      formatSpec = iff(iscell(formatSpec), formatSpec, @(){formatSpec});
      for i = 1:nargout
        [varargout{i}] = applyTransferFun(...
          sigs{:}, 'sig.transfer.mapn', {f,i}, formatSpec{i});
      end
    end
    
    function sc = scan(varargin)
      % acc = items.scan(f, seed)
      %   or
      % acc = scan(items1, f1, items2, f2, ..., seed, ['pars', p1, p2, ...])
      parsidx = find(cellfun(@(a)ischar(a) && strcmpi(a, 'pars'), varargin));
      if ~isempty(parsidx)
        pars = varargin(parsidx+1:end);
        varargin = varargin(1:parsidx - 1);
      else
        pars = {};
      end
      seed = varargin{end};
      elems = varargin(1:2:end-1);
      funcs = varargin(2:2:end-1);
      % formatting
      funStrs = mapToCell(@toStr, funcs);
      elemStrs = mapToCell(@(e)'%s', elems);
      formatSpec = ['%s.scan(' strJoin(reshape([funStrs; elemStrs], 1, []), ', ') ')'];
      if ~isempty(pars)
        formatSpec = [formatSpec '[' strJoin(mapToCell(@(e)'%s', pars), ', ') ']'];
      end
      % derive the scanning signal
      inps = sig.node.from([elems {seed} pars]); % input signals & values -> nodes
      node = sig.node.Node(inps, 'sig.transfer.scan', funcs);
      node.FormatSpec = formatSpec;
      sc = sig.node.ScanningSignal(node);
      if node.Net.Debug; node.Net.NodeName(node.Id) = sc.Name; end
      % initialise value of derived signal using seed
      if isa(seed, 'sig.node.Signal') % if seed is a signal, use its current value, if any
        if seed.Node.CurrValueSet
          sc.Node.CurrValue = seed.Node.CurrValue;
        end
      else % seed not a signal, so use it directly as the value
        sc.Node.CurrValue = seed;
      end
    end

    function r = iff(pred, trueVal, falseVal)
      if nargin > 2
        r = cond(pred, trueVal, true, falseVal);
      else
        r = cond(pred, trueVal);
      end
    end

    function c = cond(pred1, value1, varargin)
      preds = [{pred1} varargin(1:2:end)];
      vals = [{value1} varargin(2:2:end)];
      
      assert(numel(preds) == numel(vals));
      nc = numel(preds);
      
      firstTrue = indexOfFirst(preds{:});
      c = firstTrue.selectFrom(vals{:});
      
      valuePredNodes = [c.Node.Inputs(2:end) ; firstTrue.Node.Inputs];
      % 'display' inputs is a sequence of value,predicate pairs
      c.Node.DisplayInputs = valuePredNodes(:);
      c.Node.FormatSpec = [...
        'cond( ' strJoin(repmat({'%s if %s'}, nc, 1), ' ; ') ' )'];
      net = c.Node.Net;
      if net.Debug; net.NodeName(c.Node.Id) = c.Name; end
    end
    
    function s = selectFrom(this, varargin)
      formatSpec = [...
        '%s.selectFrom([ ' strJoin(repmat({'%s'}, numel(varargin), 1), ' ; ') ' ])'];
      s = applyTransferFun(this, varargin{:}, 'sig.transfer.selectFrom', [], formatSpec);
    end
    
    function f = indexOfFirst(varargin)
      formatSpec = [...
        'indexOfFirst([ ' strJoin(repmat({'%s'}, nargin, 1), ' ; ') ' ])'];
      f = applyTransferFun(varargin{:}, 'sig.transfer.indexOfFirst', [], formatSpec);
    end
    
    function b = bufferUpTo(this, nSamples)
      % b = s.bufferUpTo(n) returns a signal which holds an array of values
      % of the input signal for the last nSamples. nSamples may be a whole
      % number or a signal.
      %
      % Example:
      %   latest = s.bufferUpTo(5)
      formatSpec = '%s.bufferUpTo(%s)';
      b = applyTransferFun(this, nSamples, 'sig.transfer.buffer', [], formatSpec);
      net = b.Node.Net;
      if net.Debug; net.NodeName(b.Node.Id) = b.Name; end
    end
    
    function b = buffer(this, nSamples)
      % b = s.buffer(n) returns a signal which holds the last n values
      % the input signal.  The number of samples to buffer may be a whole
      % number or a signal.  Unlike bufferUpTo, buffer will not update until
      % the signal to buffer has updated at least n times.
      %
      % Example:
      %   % Buffer the last 5 values of 's'
      %   latest = s.buffer(5)
      %
      % See also SIG.SIGNAL.BUFFERUPTO
      
      buffupto = bufferUpTo(this, nSamples);
      nelem = size(buffupto, 2);
      b = buffupto.keepWhen(nelem == nSamples);
      b.Node.DisplayInputs = buffupto.Node.DisplayInputs;
      b.Node.FormatSpec = '%s.buffer(%s)';
      net = b.Node.Net;
      if net.Debug; net.NodeName(b.Node.Id) = b.Name; end
    end
    
    function m = merge(varargin)
      % m = merge(s1...sN) returns a signal which takes the value of the
      % most recent input signal to update. If multiple signals update
      % during the same transaction, the signal value which occurs earlier
      % in the input argument list is used.
      %
      % Example:
      %   latest = a.merge(b)
      %   latest.Name % a ~ b
      formatSpec = ['( ' strJoin(repmat({'%s'}, 1, nargin), ' ~ ') ' )'];      
      m = applyTransferFun(varargin{:}, 'sig.transfer.merge', [], formatSpec);
    end
    
    function p = to(a, b)
      p = applyTransferFun(a, b, 'sig.transfer.latch', [], '%s.to(%s)');
      p.Node.CurrValue = false;
    end
    
    function tr = setTrigger(set, release)
      armed = set.to(release);
      tr = at(true, ~armed); % samples true each time armed goes to false
      tr.Node.FormatSpec = '%s.setTrigger(%s)';
      tr.Node.DisplayInputs = [set.Node release.Node];
      net = tr.Node.Net;
      if net.Debug; net.NodeName(tr.Node.Id) = tr.Name; end
    end
    
    function tr = setEpochTrigger(newPeriod, t, x, threshold)
      % returns a signal that is triggered when another signal doesn't
      % change over some time period
      %
      % Inputs:
      %   newPeriod - a signal containing the period of time over which
      %     to check if signal x has had its value changed more than
      %     the threshold
      %   t - a signal for time-keeping
      %   x - a signal that triggers qevt when its value doesn't change
      %     by more than threshold over newPeriod
      %   threshold - a numeric value that sets the maximum amount x
      %     can change by within newPeriod to trigger qevt
      %
      % Outputs:
      %   qevt - a signal that is triggered when x changes by less than
      %     threshold over newPeriod
      
      if nargin < 4, threshold = 0; end
      [initState, tUpdate, xUpdate] = sig.scan.quiescienceWatch;
      
      newState = newPeriod.map(initState);
      
      state = scan(t.delta(), tUpdate,... scan time increments
        x.delta(), xUpdate,... scan x deltas
        newState,... initial state on arming trigger
        'pars', threshold); % parameters
      state = state.subscriptable(); % allow field subscripting on state
      
      % event signal is derived by monitoring the 'armed' field of state
      % for new false values (i.e. when the armed trigger is released).
      armed = subsref(state, struct('type', '.', 'subs', 'armed'));
      tr = armed.skipRepeats().not().then(true);
      tr.Node.DisplayInputs = [
        state.Node.DisplayInputs([2,1,4,1]) newPeriod.Node];
      tr.Node.FormatSpec = '%s/%s < %s s.t. %s = %s';
      % Set armed to false
      tr.Node.CurrValue = false;
    end
    
    function nr = skipRepeats(this)
      nr = applyTransferFun(this, 'sig.transfer.skipRepeats', [],  '(*%s)');
    end
    
    function l = lag(this, n)
      b = buffer(this, n + 1);
      l = b.map(@(v)v(1), sprintf('%%s.lag(%i)', n));
      l.Node.DisplayInputs = this.Node;
      net = b.Node.Net;
      if net.Debug; net.NodeName(l.Node.Id) = l.Name; end
    end
    
    function d = delta(this)
      d = map(buffer(this, 2), @diff);
      d.Node.DisplayInputs = this.Node;
      d.Node.FormatSpec = [char(916) '%s']; % char(916) is the delta character
      net = d.Node.Net;
      if net.Debug; net.NodeName(d.Node.Id) = d.Name; end
    end
    
    function d = delay(this, period)

      % The scheduler creates a cell 'packet' with the new value to be
      % delayed and the current delay value.
      scheduler = applyTransferFun(...
        this, period, 'sig.transfer.schedule', [], '%s.schedule(%s)');
      % This packet will be 'delay posted' into d using a timer.
      d = sig.node.OriginSignal(sig.node.Node(this.Node.Net));
      d.Node.FormatSpec = '%s.delay(%s)';
      d.Node.DisplayInputs = scheduler.Node.DisplayInputs;
      % Store name while debugging
      net = d.Node.Net;
      if net.Debug; net.NodeName(d.Node.Id) = d.Name; end

      delayedpost = scheduler.onValue(fun.partial(@delayedPost, d));
      
      % For complicated reasons, making a further identity signal from d to
      % hold the listener handle helps ensure it can be garbage collected:
      %   The handle can't be held by an object it holds a reference to
      % TODO Try storing the handle in Signal Listeners prop, not Node's
      d = identity(d);
      d.Node.Listeners = [d.Node.Listeners delayedpost];
    end
    
    function id = identity(this)
      id = applyTransferFun(this, 'sig.transfer.identity', [], this.Node.FormatSpec);
      % the identity function should display exactly as this one does, i.e.
      % look like it has the same inputs, use the same format spec
      id.Node.DisplayInputs = this.Node.DisplayInputs;
    end
    
    function fs = flatten(this)
      % Flattens a nested signal down to its value.
      % 
      % Returns a signal whose value is a flattened version of this
      % signal's value: If the current value is itself a signal (as is the
      % case with subscriptable signals), the value it holds will be
      % returned, rather than a Signal object itself.
      
      state = StructRef;
      state.unappliedInputChanges = false;
      fs = applyTransferFun(this, 'sig.transfer.flatten', state,...
        '%s.flatten()');
    end
    
    function fs = flattenStruct(this)
      % Flattens nested signal fields down to their values.
      %
      % Returns a signal `fs` whose value is a struct containing 
      % flattened values for the signal fields in `this`: if `this` is a 
      % subscriptable signal or a signal whose value is a struct containing
      % some signal fields, `fs` takes the value those signal fields hold, 
      % rather than taking the value of the signal fields themselves.
      %
      % `fs` uses `this` as a blueprint to wire up signals as inputs to
      % itself. The values of the signal fields in `this` will be directly 
      % set as `fs`'s struct field values. This is done in mexnet according
      % to the transfer opCode.
      
      fs = applyTransferFun(this, 'sig.transfer.flattenStruct', [], '%s.flattenStruct()');

    end
    

    function l = log(this, clockFun)
      % Creates signals that logs the values and timestamps of input signal
      %
      % Sometimes you want the values of a signal to be logged and
      % timestamped. The log method returns a signal that carries a
      % structure with the fields 'time' and 'value'.  Log takes two
      % inputs: the signal to be logged and an optional clock function to
      % use for the timestamps.  The default clock function is GetSecs
      %
      % NB: This doesn't have anything to do with logarithms.  To take the
      % log of a signal: logA = a.map(@log)
      if nargin < 2
        clockFun = @GetSecs;
      end
      node = sig.node.Node(this.Node, 'sig.transfer.log', clockFun, true);
      node.FormatSpec = '%s.log()';
      l = sig.node.Signal(node);
      l.Node.CurrValue = struct('time', {}, 'value', {});
      % Store name for debugging
      net = node.Net;
      if net.Debug; net.NodeName(node.Id) = l.Name; end
    end
    
    function h = onValue(this, fun)
      callbackidx = this.NextCallbackId + 1;
      this.NextCallbackId = callbackidx;
      this.OnValueCallbacks(callbackidx) = fun;
      if length(this.OnValueCallbacks) == 1 % just added to an empty list
        % so we now need to listen to mxnode events
        setNodeEventTarget(this.Node.NetId, this.Node.Id, this);
      end
      h = TidyHandle(@unsub);
      function unsub()
        this.OnValueCallbacks.remove(callbackidx);
        if isempty(this.OnValueCallbacks) % list now empty
          % remove us as the event target from the mxnode
          setNodeEventTarget(this.Node.NetId, this.Node.Id, []);
        end
      end
    end
    
    function h = output(this)
      % OUTPUT Display current value each update
      %   Prints the value of this Signal to the command window each time
      %   it updates.  Returns a listener handle which when cleared removes
      %   this callback.
      %
      % See also onValue
      h = onValue(this, @disp);
    end
    
    function varargout = size(varargin)
      % [sz1,...,szN] = size(x) or szdim = size(x,dim) returns the size of
      % signal x, optionally over dimension dim.
      if nargout > 1
        formatSpec = strcat({'size(%s) over dim '}, int2str((1:nargout)'));
      elseif nargin > 1
        formatSpec = 'size(%s) over dim %s';
      else
        formatSpec = 'size(%s)';
      end
      
      if nargin == 1 && nargout == 1
        varargout{1} = map(varargin{1}, @size, formatSpec);
      else
        [varargout{1:nargout}] = mapn(varargin{:}, @size, formatSpec);
        if nargout > 1
          % Replace the first Signal with one that calls size(x,1),
          % ensuring value is not [m n] as is the default when size is
          % called with one output argument
          formatSpec = [formatSpec{1}(1:end-1),'%s'];
          [varargout{1}] = mapn(varargin{1}, 1, @size, formatSpec);
        end
      end
    end
    
    function [varargout] = subsref(a, s)
      for ii = 1:length(s)
        switch s(ii).type
          case '.'
            [varargout{1:nargout}] = builtin('subsref', a, s(ii:end));
            return;
          case '()' % signal with array subscripted values from b
            subs = s(ii).subs;
            inpform = strJoin(repmat({'%s'}, 1, numel(subs)), ',');
            formatSpec = ['%s(' inpform ')'];
            b = applyTransferFun(...
              a, subs{:}, 'sig.transfer.subsref', '()', formatSpec);
          case '{}'
            [varargout{1:nargout}] = builtin('subsref', a, s(ii:end));
            return;
        end
      end
      varargout = {b};
    end
    
    function h = into(from, to)
      % INTO Update `to` when `from` updates
      %   Posts value of this signal into an origin signal each time this
      %   updates.  Returns a listener handle which when cleared removes
      %   this callback.
      %
      % See also onValue
      assert(isa(to, 'sig.node.OriginSignal'), ...
        'signals:Signal:into:incorrectTarget', ...
        'Target signal must be origin signal')
      h = onValue(from, @(v)post(to, v));
    end

    function valueChanged(this, newValue)
      % VALUECHANGED Trigger callbacks with new value
      %   Called by mexnet when node value updated.  Calls each function in
      %   OnValueCallbacks list with newValue.
      %
      % See also onValue, SetNodeEventTarget
      callbacks = this.OnValueCallbacks.values();
      n = numel(callbacks);
      for ii = 1:n
        callbacks{ii}(newValue);
      end
    end
    
    function n = node(this)
      n = this.Node;
    end
  end
  
  methods (Access = protected)
    function tr = applyTransferFun(varargin)
      % New signal derived by applying a transfer function to input node(s)
      % 
      % This function creates a node from the nodes of input values (these 
      % input values can be signals or non-signals), then creates a new 
      % signal from the new node.
      %
      % Transfer functions work at a lower level than transformations like 
      % `map` or `mapn`, instead operating directly with the underlying 
      % input nodes and output node, potentially using both their current 
      % *and* new values.
      %
      % [tr] = s1.applyTransferFun([s2], ..., funName, funArg, formatSpec)
      % 
      % Inputs:
      %   `s2`: an input value/signal (there can be multiple as separate 
      %   args)
      %   `funName`: a string of the name of the transfer function to be 
      %   applied 
      %   `funArg`: an optional function handle which can be applied by the
      %   transfer function
      %   `formatSpec`: an optional string which is used to format the name 
      %   of the output signal
      %
      % Outputs: `tr`: output signal
      %
      % Examples: 
      %   tr = s1.applyTransferFun(s2, 'mapn', @plus)
      %   tr = s1.applyTransferFun(s2, 5, 'mapn', @plus, '%s.mapn(%s, %s)')
      %
      % *Note: The transfer function will be passed `funArg`, if existing,
      % at each invocation.
            
      [inpVals{1:nargin-3}, funName, funArg, formatSpec] = varargin{:}; % destructure input args
      inpNodes = sig.node.from(inpVals); % get/create nodes from/for input vals
      node = sig.node.Node(inpNodes, funName, funArg); % create node for output signal
      node.FormatSpec = formatSpec;
      tr = sig.node.Signal(node); % build new signal from new node
      net = node.Net;
      if net.Debug; net.NodeName(tr.Node.Id) = tr.Name; end
    end
  end
  
  methods (Static)
    function y = end(k, n)
      y = expr.End(k, n);
    end
  end
end

