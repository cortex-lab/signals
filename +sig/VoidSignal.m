classdef VoidSignal < sig.Signal
  % SIG.VOIDSIGNAL Signal mock class
  %   A mock Signal class with all methods subclassed so that they return
  %   the same object instance.  This is used as input arguments when
  %   calling Signals definition functions without requiring a network.  If
  %   the CacheSubscripts flag has been set to true, all subscript
  %   references are stored in the Subscripts property.
  %
  % See also exp.inferParameters
  
  properties (Hidden)
    % Flag indicating whether to record object subscript references
    CacheSubscripts = false
  end
  
  properties (Access = private)
    % Struct containing field names corresponding to subscript references
    Subscripts
  end
  
  methods
    function mapped = map(this, f, varargin)
      mapped = this;
    end
    
    function mapped = map2(this, other, f, varargin)
      mapped = iff(isa(this, 'sig.VoidSignal'), @()this, @()other);
    end
    
    function mapped = mapn(this, varargin)
      mapped = sig.VoidSignal.instance(0);
    end
    
    function scanning = scan(this, f, seed, varargin)
      scanning = this;
    end
    
    function d = lag(this, n)
      d = this;
    end
    
    function d = delay(this, period)
      d = this;
    end
    
    function c = cond(this, varargin)
      c = this;
    end
    
    function s = at(this, when)
      s = iff(isa(this, 'sig.VoidSignal'), @()this, @()when);
    end
    
    function s = then(when, this)
      s = at(when, this);
    end

    function s = keepWhen(this, when)
      s = this;
    end
    
    function h = onValue(this, fun)
      h = TidyHandle.empty;
    end
    
    function h = output(this)
      h = TidyHandle.empty;
    end
    
    function l = log(this, clockFun)
      l = this;
    end
    
    function id = identity(this)
      id = this;
    end
    
    function d = delta(this)
      d = this;
    end
    
    function nr = skipRepeats(this)
      nr = this;
    end
    
    function tr = setTrigger(set, release)
      tr = set;
    end
    
    function p = to(a, b)
      p = a;
    end
    
    function m = merge(varargin)
      m = sig.VoidSignal.instance(0);
    end
    
    function b = bufferUpTo(this, nSamples)
      b = this;
    end
    
    function b = buffer(this, nSamples)
      b = this;
    end
    
    function f = indexOfFirst(varargin)
      f = sig.VoidSignal.instance(0);
    end
    
    function s = selectFrom(this, varargin)
      s = this;
    end
    
    function s = flattenStruct(this)
      s = this;
    end
    
    function s = flatten(this)
      s = this;
    end
    
    function s = end(this, k, n)
      s = this;
    end
    
    function c = iff(this, that, theother)
      c = sig.VoidSignal.instance(0);
    end
    
    function s = subscriptable(this)
      s = this;
    end
    
    function s = into(this, that)
      s = this;
    end
    
   function s = size(this, dim)
      s = this;
    end
    
    function [varargout] = subsref(a, s)
      % SUBSREF Subscripted reference for VoidSignal
      %  If the subscript name is a method then that method is called.  If
      %  CacheSubscripts is true, the name of the subscript is recorded in
      %  the Subscripts property.  If the Subscripts property is being
      %  accessed, then it is returned as expected.  All other subscripts
      %  return the same instance of this class.
      %  NB: multi-level subsref is not extensively supported.
      
      % By default return the same instance of void as this
      [varargout{1:nargout}] = deal(a);
      
      name = s(1).subs;
      % If the subscript is a void signal then we're indexing with another
      % signal so return
      if ~ischar(name); return
      elseif ismember(name, [{'Subscripts'}; methods(a)])
      % Otherwise if the subscript is a method or the Subscripts property,
      % use the builtin methods instead
        [varargout{1:nargout}] = builtin('subsref', a, s);
        return
      end
      
      % If we're caching subscripts and this one is new, add fieldname to
      % Subscripts struct
      if a.CacheSubscripts && ~ismember(name, fieldnames(a.Subscripts))
        a.Subscripts.(name) = [];
      end
    end
    
    function A = subsasgn(this, s, varargin)
      % SUBSASGN Subscripted assignment for VoidSignal
      %  Always returns the same instance of this class.  If the
      %  CacheSubscripts property is set to true and there is a dot
      %  assignment to a previously referenced subscript, then the value is
      %  assigned to that field of the Subscripts property.
      %
      %  NB: multi-level subassign is not currently supported.
      dotname = s(1).subs;
      if this.CacheSubscripts && strcmp(s(1).type,'.') ...
          && isfield(this.Subscripts, dotname)
        this.Subscripts.(dotname) = varargin{1};
      end
        A = this; % Return the same instance of void as this
    end
  end
  
  methods (Access = private)
    function this = VoidSignal()
      this.Subscripts = struct;
    end
  end

  methods (Static)
    function s = instance(cache)
      persistent inst;
      if cache
        s = sig.VoidSignal;
        s.CacheSubscripts = true;
      else
        if isempty(inst)
          inst = sig.VoidSignal;
        end
        s = inst;
      end
    end
  end
  
end

