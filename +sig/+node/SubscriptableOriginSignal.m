classdef SubscriptableOriginSignal < sig.node.SubscriptableSignal & ...
    sig.node.OriginSignal
  
  % sig.node.SubscriptableOriginSignal Dot syntax assigning of values
  %   A sig.node.SubscriptableOriginSignal can be updated vis subscripted
  %   assignment (e.g. S.I = a).  The signal's value is a struct and each
  %   assignment updates a field of the underlying struct.  Currently
  %   multi-level subscripted assignment is not implemented.
  %
  %   Subscripted referencing is also supported, returning a new signal
  %   whose value results from subscripting the underlying struct's value.
  %   For single-level references, the underlying field does not have to
  %   exist. Multi-level subscripted references can also be made (e.g. s =
  %   S.a.b.c), although for these, the underlying fields must already
  %   exist.
  %
  % See also sig.node.SubscriptableSignal
  
  methods
    function this = SubscriptableOriginSignal(node, varargin)
      this = this@sig.node.SubscriptableSignal(node, varargin{:});
      this = this@sig.node.OriginSignal(node);
      this.Deep = true; % Allow 2-level subscripted referencing
    end
    
    function a = subsasgn(a, s, b)
      % todo: this function is currently hacky
      if isa(a, 'sig.node.SubscriptableOriginSignal')
        if s(1).type == '.' && any(strcmp(s(1).subs, a.Reserved))
          a = builtin('subsasgn', a, s, b);
        else
          assert(numel(s) == 1, 'todo');
          newValue = subsasgn(a.Node.CurrValue, s(1), b);
          post(a, newValue);
        end
      else
        a = builtin('subsasgn', a, s, b);
      end
    end
    %
    %     function [varargout] = subsref(a, s)
    %       [varargout{1:nargout}] = subsref@sig.node.SubscriptableSignal(a, s);
    %     end
  end
  
end

