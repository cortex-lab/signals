classdef Signal < sig.Signal & handle
  % sig.node.Signal Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (Dependent)
    Name
  end
  
  properties (Hidden, SetAccess = immutable)
    Node
  end
  
  properties %(SetAccess = private, Transient)
    OnValueCallbacks
    NextCallbackId = 0
    Listeners
  end
  
  methods
    function this = Signal(node)
      this.Node = node;
      this.OnValueCallbacks = containers.Map('KeyType', 'int32', 'ValueType', 'any');
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
    end
    
    function y = end(this, k, n)
      warning('FYI, end being called on sig.node.Signal ''%s''', toStr(this.Name));
      y = expr.End(k, n);
    end
    
    function s = at(what, when)
      s = applyTransferFun(what, when, 'sig.transfer.at', [], '%s.at(%s)');
    end
    
    function s = then(when, what)
      s = applyTransferFun(what, when, 'sig.transfer.at', [], '%s.then(%s)');
      s.Node.DisplayInputs = fliplr(s.Node.DisplayInputs);
    end
    
    function f = keepWhen(what, when)
      f = applyTransferFun(what, when, 'sig.transfer.keepWhen', [], '%s.keepWhen(%s)');
    end
    
    function m = map(this, f, varargin)
      if numel(varargin) > 0
        formatSpec = varargin{1};
      else
        formatSpec = sprintf('%%s.map(%s)', toStr(f));
      end
      if ~isa(f, 'function_handle') % always map to a value
        f = fun.always(f);
      end
      m = applyTransferFun(this, 'sig.transfer.map', f, formatSpec);
    end
    
    function m = map2(sig1, sig2, f, varargin)
      m = mapn(sig1, sig2, f, varargin{:});
    end
    
    function m = mapn(varargin)
      % destructure varargin
      if isa(varargin{end}, 'function_handle')
        [sigs{1:nargin-1}, f] = varargin{:};
        formatSpec = sprintf(['mapn(' repmat('%%s, ', 1, numel(sigs)) '%s)'], toStr(f));
      else
        [sigs{1:nargin-2}, f, formatSpec] = varargin{:};
      end
      m = applyTransferFun(sigs{:}, 'sig.transfer.mapn', f, formatSpec);
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
      %% formatting
      funStrs = mapToCell(@toStr, funcs);
      elemStrs = mapToCell(@(e)'%s', elems);
      formatSpec = ['%s.scan(' strJoin(reshape([elemStrs; funStrs], 1, []), ', ') ')'];
      if ~isempty(pars)
        formatSpec = [formatSpec '[' strJoin(mapToCell(@(e)'%s', pars), ', ') ']'];
      end
      %% derive the scanning signal
      inps = sig.node.from([elems {seed} pars]); % input signals & values -> nodes
      node = sig.node.Node(inps, 'sig.transfer.scan', funcs);
      node.FormatSpec = formatSpec;
      sc = sig.node.ScanningSignal(node);
      % initialise value of derived signal using seed
      if isa(seed, 'sig.node.Signal') % if seed is a signal, use its current value, if any
        if seed.Node.CurrValueSet
          sc.Node.CurrValue = seed.Node.CurrValue;
        end
      else % seed not a signal, so use it directly as the value
        sc.Node.CurrValue = seed;
      end
    end
    
%     function sc = scanAsArgs(this, f, seed, formatSpec)
%       if nargin < 4
%         argsStr = strJoin(repmat({'%%s'}, 1, numel(sigs)), ', ');
%         formatSpec = sprintf(['scanAsArgs({' argsStr  '}, %s, %s)'],...
%           toStr(f), toStr(seed));
%       end
%       sNode = sig.node.Node(this.Node, 'sig.transfer.scanAsArgs', f);
%       sNode.FormatSpec = formatSpec;
%       sNode.CurrValue = seed;
%       sc = sig.node.Signal(sNode);
%     end
    
%     function sc = scanAsArgs(this, f, seed, formatSpec)
%       if nargin < 4
%         argsStr = strJoin(repmat({'%%s'}, 1, numel(sigs)), ', ');
%         formatSpec = sprintf(['scanAsArgs({' argsStr  '}, %s, %s)'],...
%           toStr(f), toStr(seed));
%       end
%       sNode = sig.node.Node(this.Node, 'sig.transfer.scanAsArgs', f);
%       sNode.FormatSpec = formatSpec;
%       sNode.CurrValue = seed;
%       sc = sig.node.Signal(sNode);
%     end

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
      
      % todo: implement as a transfer function
      b = scan(this, sig.scan.buffering(nSamples), []);
      b.Node.FormatSpec = sprintf('%%s.bufferUpTo(%i)', nSamples);
    end
    
    function b = buffer(this, nSamples)
      buffupto = bufferUpTo(this, nSamples);
      nelem = size(buffupto, 2);
      b = buffupto.keepWhen(nelem == nSamples);
      b.Node.DisplayInputs = this.Node;
      b.Node.FormatSpec = sprintf('%%s.buffer(%i)', nSamples);
    end
    
%     function b = bufferUpTo(this, nSamples)
%       
%       % Create a scanner that pairs the value with the sample count
%       value_count = scan(this, fun.restrictScope(@(v,acc){v acc{2}+1}), {[] 0});
%       % Scan this info to accumulate and slice an array
%       circ_count = scan(value_count, @circbuff, {[] []});
%       b = map(circ_count, @recent);
%       b.Node.DisplayInputs = this.Node;
%       b.Node.FormatSpec = sprintf('%%s.bufferUpTo(%i)', nSamples);
%       function circ_cnt = circbuff(val_cnt, circ_cnt)
%         circ_cnt{2} = val_cnt{2};
%         if numel(circ_cnt{1}) < nSamples % grow stage
%           circ_cnt{1} = [circ_cnt{1} val_cnt{1}];
%         else % slice into next circular position
%           idx = mod(val_cnt{2} - 1, nSamples) + 1;
%           circ_cnt{1}(idx) = val_cnt{1};
%         end
%       end
%       function buff = recent(circ_cnt)
%         if numel(circ_cnt{1}) < nSamples % grow stage
%           buff = circ_cnt{1};
%         else
%           reslice = mod((-nSamples:-1) + circ_cnt{2}, nSamples) + 1;
%           buff = circ_cnt{1}(reslice);
%         end
%       end
%     end

    function m = merge(varargin)
      formatSpec = ['( ' strJoin(repmat({'%s'}, 1, nargin), ' ~ ') ' )'];      
      m = applyTransferFun(varargin{:}, 'sig.transfer.merge', [], formatSpec);
    end
    
    function p = to(a, b)
      p = applyTransferFun(a, b, 'sig.transfer.latch', [], '%s.to(%s)');
      p.Node.CurrValue = false;

%       p = skipRepeats(merge(map(a, @logical), ~b));
%       p.Node.DisplayInputs = [a.Node b.Node];
%       p.Node.FormatSpec = '%s.to(%s)';
    end
    
    function tr = setTrigger(set, release)
      armed = set.to(release);
      tr = at(true, ~armed); % samples true each time armed goes to false
      tr.Node.FormatSpec = '%s.setTrigger(%s)';
      tr.Node.DisplayInputs = [set.Node release.Node];
    end
    
    function nr = skipRepeats(this)
      nr = applyTransferFun(this, 'sig.transfer.skipRepeats', [],  '(*%s)');
    end
    
    function l = lag(this, n)
      b = buffer(this, n + 1);
      l = b.map(@(v)v(1), sprintf('%%s.lag(%s)', n));
    end
    
    function d = delta(this)
      d = map(buffer(this, 2), @diff);
      d.Node.DisplayInputs = this.Node;
      d.Node.FormatSpec = [char(916) '%s']; % char(916) is the delta character
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
      delayedpost = scheduler.onValue(fun.partial(@delayedPost, d));
      
      % For complicated reasons, making a further identity signal from d to
      % hold the listener handle helps ensure it can be garbage collected:
      %   The handle can't be held by an object it holds a reference to
      d = identity(d);
      d.Node.Listeners = [d.Node.Listeners delayedpost];
    end
    
    function id = identity(this)
      id = applyTransferFun(this, 'sig.transfer.identity', [], this.Node.FormatSpec);
      % the identity function should display exactly as this one does, i.e.
      % look like it has the same inputs, use the same format spec
      id.Node.DisplayInputs = this.Node.DisplayInputs;
    end
    
    function fs = flattenStruct(this)
      % Use a struct with signal fields as a blueprint to wire up signals
      % as inputs to this target so that their values will set the field
      % values directly in the target's struct value all done in mexnet
      % according to the transfer opcode
      fs = applyTransferFun(this, 'sig.transfer.flattenStruct', [], '%s.flattenStruct()');
%       state = StructRef;
%       state.unappliedInputChanges = false;
%       state.inputsToSubsref = containers.Map(...
%         'KeyType', 'uint64', 'ValueType', 'any');
%       fs = applyTransferFun(this, 'sig.transfer.flattenStruct', state,...
%         '%s.flattenStruct()');
    end

    function fs = flatten(this)
      % all done in mexnet according to the transfer opcode
      state = StructRef;
      state.unappliedInputChanges = false;
      fs = applyTransferFun(this, 'sig.transfer.flatten', state,...
        '%s.flatten()');
    end
    
    function tr = applyTransferFun(varargin)
      % New signal derived by applying a transfer function to input nodes
      %
      % [tr] = s1.applyTransfer([s2], ..., funName, funArg, formatSpec)
      % returns a new signal tr whose values result from applying a
      % transfer function called funName to a variable number of input
      % signals or constant values. Transfer functions work at a lower
      % level than transformations like like map or mapn, instead operating
      % directly with the underlying input nodes and output node,
      % potentially using both their current *and* new values.
      %
      % This function creates a node with input nodes from each of the
      % signals s1, s2,... (or for each non-signal values, creates a
      % 'constant' node with that value). It then returns a sig.node.Signal
      % tr containing the new node. It also sets the node's FormatSpec
      % property as formatSpec.
      %
      % The transfer function will also be passed the funArg variable at
      % each invocation.
      
      % destructure arguments:
      [sigs{1:nargin-3}, funName, funArg, formatSpec] = varargin{:};
      inps = sig.node.from(sigs); % input signals & values -> nodes
      node = sig.node.Node(inps, funName, funArg);
      node.FormatSpec = formatSpec;
      tr = sig.node.Signal(node);
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
      h = onValue(this, @disp);
    end
    
    function s = size(x, dim)
      if nargin > 1
        s = map2(x, dim, @size);
      else
        s = map(x, @size);
      end
    end
    
    function [varargout] = subsref(a, s)
      b = a;
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
      h = onValue(from, @(v)post(to, v));
    end

    function valueChanged(this, newValue)
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
  end
end

