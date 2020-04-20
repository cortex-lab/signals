function [val, valset] = identity(net, input, node, ~)
% SIG.TRANSFER.IDENTITY Tranfer the value input node
%   Returns the working value of the input node if set.
%
%   Inputs:
%     net (int) - id of Signals network to whom nodes belong.
%     input (int) - input node id.
%     node (int) - id of node whose value is to be assigned the output.
%
%   Outputs:
%     val (*) - the input's working value if set.  Value is assigned to `node`.
%     valset (logical) - true if the input's working value is set.
%
%   Example:
%     % Logic for returning value of node 2 network 0 for assigning to node
%     % 3 (done in mexnet): 
%     val = sig.transfer.identity(0, 2, 3)
%
% See also sig.node.Signal/applyTransferFun sig.node.Signal/identity
[wv, wvset] = workingNodeValue(net, input);% assumes one input only
if wvset
  % canonical line: identity: input->output 
  val = wv;
  valset = true;
else % input has no value -> no output value
  val = [];
  valset = false;
end
