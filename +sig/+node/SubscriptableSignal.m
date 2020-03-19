classdef SubscriptableSignal < sig.node.Signal
  %sig.SubscriptableSignal Dot syntax subscripting to derive new signals
  %   A sig.SubscriptableSignal can be subscripted to obtain a new
  %   signal whose value results from subscripting the parent's value.
  
  properties
    CacheSubscripts = false
  end
  
  properties (SetAccess = protected)
    Deep = false
    Subscripts
  end
  
  properties (SetAccess = protected, Transient)
    Reserved
  end
  
  methods
    function this = SubscriptableSignal(node, deep)
      this = this@sig.node.Signal(node);
      this.Subscripts = containers.Map;
      if nargin > 1
        this.Deep = deep;
      end
      this.Reserved = [methods('sig.node.Signal'); 'Name'; 'Node'
        'CacheSubscripts'; 'Subscripts'; 'Reserved'; 'Deep'];
    end
    
    function this = subscriptable(this) % just return this
    end

    function [varargout] = subsref(a, s)
      if strcmp(s(1).type, '.')
        dotname = s(1).subs;
        if isa(a, 'sig.node.Signal') &&...
            any(strcmp(a.Reserved, dotname))
          [varargout{1:nargout}] = builtin('subsref', a, s);
          return;
        end
        if isa(dotname, 'sig.node.Signal')
          formatSpec = '%s.(%s)';
        else
          formatSpec = '%s.%s';
        end
        if a.CacheSubscripts && isKey(a.Subscripts, dotname)
          a = a.Subscripts(dotname);
        else
          subscript = applyTransferFun(...
            a, dotname, 'sig.transfer.subsref', '.', formatSpec);
          if a.CacheSubscripts
            a.Subscripts(dotname) = subscript;
          end
          a = subscript;
        end
        if length(s) > 1 % recurse on the rest of the subscripts
          [varargout{1:nargout}] = subsref(a, s(2:end));
        else
          varargout = {a};
        end
      else
        [varargout{1:nargout}] = subsref@sig.node.Signal(a, s);
      end
    end
  end  
end

