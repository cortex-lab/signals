function code = transfererOpCode(transFun, transArg)
%TRANSFEREROPCODE Returns the operation code associated with transfer fun
%   Returns the transfer op code associated with the input transfer
%   function and optional transfer argument. This is called by the
%   sig.node.Node constructor and used when adding new nodes to the
%   network.  The MEX code uses this code to determine which transfer
%   function to envoke.
%
%   Inputs:
%     transFun (char) : The transfer function name
%     transArg (function_handle) : The (optional) transfer argument,
%       expected to be a function for map and mapn
%
%   Output:
%     code (int) : The associated operation code used in mexnet
%
%   Example:
%     % Get the op code for mapping signal to numel
%     code = sig.node.transfererOpCode('sig.transfer.map', @numel)
%
% See also sig.node.Node, addNode, network/transfer

code = 0; % default op code: means just use matlab transfer function

switch transFun
%   case 'sig.transfer.identity'
%     code = 50;
  case {'sig.transfer.mapn' 'sig.transfer.map'}
    if isa(transArg, 'function_handle')
      switch func2str(transArg)
        case 'plus'
          code = 1; % +
        case 'minus'
          code = 2; % -
        case 'times'
          code = 3; % .*
        case 'mtimes'
          code = 4; % *
        case 'rdivide'
          code = 5; % ./
        case 'mrdivide'
          code = 6; % /
        case 'gt'
          code = 10; % >
        case 'ge'
          code = 11; % >=
        case 'lt'
          code = 12; % <
        case 'le'
          code = 13; % <=
        case 'eq'
          code = 14; % ==
        case 'numel'
          code = 30;
      end
    end
  case 'sig.transfer.flattenStruct'
    code = 40;
end

end

