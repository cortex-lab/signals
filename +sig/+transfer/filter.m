function [val, valset] = filter(net, inputs, node, f)
% SIG.TRANSFER.FILTER Filter signal using function
%   Assigns the working value of input if the output of f(input) matches
%   the criterion. Always assumes input nodes = [what, criterion].
%
%   Inputs:
%     net (int) - id of Signals network to whom input nodes belong
%     inputs (int) - array of input node ids whose values are to be mapped
%       through a function
%     node (int) - id of node whose value is to be assigned the output
%     f (function_handle) - a function to test whether to keep input value
%
%   Outputs:
%     val (*) - the input value if it passes the function criterion.
%       Value is assigned to node.
%     valset (logical) - true if the first input node has a working value.
%
%   Example:
%     % Logic for filtering values of node 2 given the output of f matches
%     % node 3 in network 0.  The filtered value is assigned to node 4: 
%     val = sig.transfer.buffer(0, [2 3], 4, f)
%
% See also sig.node.Signal/applyTransferFun sig.node.Signal/keepWhen

% always assumes two inputs: [what, criterion]

% obtain latest criterion value, if any
[criterion, wvset] = workingNodeValue(net, inputs(2));
if ~wvset % value follows working value first
  [criterion, wvset] = currNodeValue(net, inputs(2));
  if ~wvset % filter cannot proceed if a criterion is missing
    return
  end
end

% get working 'what' value
[what, whatset] = workingNodeValue(net, inputs(1));
% we gate on the working value existing and passing function output
if whatset
  try
    indicator = f(what);
    if indicator == criterion
      val = what;
      valset = true;
      return % only code path that sets a working output value
    end
  catch ex
    msg = sprintf(['Error in Net %i mapping Nodes [%s] to %i:\n'...
      'Calling %s on %s produced an error:\n %s'],...
      net, num2str(inputs), node, toStr(f), toStr(what,1), ex.message);
    sigEx = sig.Exception('transfer:filter:error', ...
      msg, net, node, inputs, {what, criterion}, f);
    ex = ex.addCause(sigEx);
    rethrow(ex)
  end

end

%all codepaths end here, but one
% no output
val = [];
valset = false;
