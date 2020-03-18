function [val, valset] = merge(net, inputs, ~, ~)
%SIG.TRANSFER.MERGE Return the value of most recently updated input node
%   Iterates over the input nodes and returns the first set working value.
%   This function is called by mexnet.
%
%   Inputs:
%     net (int) - id of Signals network to whom input nodes belong 
%     inputs (int) - array of input node ids whose values are to be mapped
%       through a function
%
%   Outputs:
%     val - the working node value of the first input node with a working 
%       value set.
%     valset (logical) - true if any input nodes have a working value.
%
%   Example:
%     % Logic for merging values of nodes 2 and 3 of network 0 to node 4 
%     % (via mexnet callbacks):
%     val = sig.transfer.merge(0, [2 3], 4, [])
%     
% See also sig.node.Signal/applyTransferFun sig.node.Signal/merge

for inp = 1:numel(inputs)
  [v, set] = workingNodeValue(net, inputs(inp));
  if set
    val = v;
    valset = true;
    return;
  end
end
val = [];
valset = false;