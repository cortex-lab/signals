classdef VoidSignal < sig.Signal
  % sig.VoidSignal Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (Hidden)
    CacheSubscripts = false
  end
  
  properties (Access = private)
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
      s = this;
    end

    
    function s = keepWhen(this, when)
      s = this;
    end
    
    function h = onValue(this, fun, noHFlag)
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
    
    function c = iff(this, that, theother)
      c = sig.VoidSignal.instance(0);
    end
    
    function s = subscriptable(this)
      s = this;
    end
    
    function s = into(this, that)
      s = this;
    end
    
    function [varargout] = subsref(a, s)
      dotname = s(1).subs;
      if ismember(dotname, [{'Subscripts'}; methods(a)])
        [varargout{1:nargout}] = builtin('subsref', a, s);
%         varargout = {builtin('subsref', a, struct('type', '.', 'subs', 'Subscripts'))};
        return
%       elseif ismemebr(dotname, methods(a))
%         
      end
      if a.CacheSubscripts && ~ismember(dotname, fieldnames(a.Subscripts))
        a.Subscripts.(dotname) = [];
      end
      [varargout{1:nargout}] = deal(a);
    end
    
    function A = subsasgn(this, s, varargin)
      dotname = s(1).subs;
      if this.CacheSubscripts && strcmp(s(1).type,'.') ...
          && isfield(this.Subscripts, dotname)
        this.Subscripts.(dotname) = varargin{1};
      end
        A = this;
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

