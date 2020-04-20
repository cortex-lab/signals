function [val, valset] = keepWhen(net, inputs, ~, ~)
% SIG.TRANSFER.KEEPWHEN Keep signal values when another's value is truthy
%   Assigns the working value of input if the output of f(input) matches
%   the criterion. Always assumes input nodes = [what, criterion].
%
%   Inputs:
%     net (int) - id of Signals network to whom input nodes belong.
%     inputs (int) - array of input node ids.
%
%   Outputs:
%     val (*) - the first input value if the second input value is truthy.
%       Value is assigned to node.
%     valset (logical) - true if the second input node has a truthy value.
%
%   Example:
%     % Logic for keeping value of node 2 of network 0 given the value of 
%     % node 3 is truthy (done in mexnet):
%     val = sig.transfer.keepWhen(0, [2 3])
%
% See also sig.node.Signal/applyTransferFun sig.node.Signal/filter

% always assumes two inputs: [what, when]

% get latest 'when' value
[when, whenwvset] = workingNodeValue(net, inputs(2));
if ~whenwvset
  [when, whencvset] = currNodeValue(net, inputs(2));
end
% we gate on the latest value existing and being truthy
if whenwvset || whencvset
  if when % if 'when' is truthy (i.e. not false or zero)...
    % ...get latest 'what' value
    [what, whatset] = workingNodeValue(net, inputs(1));
    % has a new 'what' value been set?
    if whatset % if so, set working output to it
      val = what;
      valset = true;
      return % only code path that sets a working output value
    end
  end
end
%all codepaths end here, but one
% no output
val = [];
valset = false;
