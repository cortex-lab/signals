classdef (Sealed) Exception < MException
% SIG.EXCEPTION Signals specific exception
%  Exception class storing details of node which caused exception.
%
% See also MException, SIG.TRANSFER
%
% 2019-09 MW created

  properties (SetAccess = private)
    Net % Network ID
    Node % Node ID
    Inputs % Input node IDs
    Values % Input node values
    Arg % Transfer function argument
  end
  
  methods
    
    function obj = Exception(id, msg, varargin)
      if ~isempty(id) && ~startsWith(id, 'signals')
        id = strjoin({'signals',id},':');
      else
        st = dbstack;
        id = strrep(st(2).name,'.',':');
      end
      obj = obj@MException(id, msg);
      [obj.Net, obj.Node, obj.Inputs, obj.Values, obj.Arg] = varargin{:};
    end
    
  end
end