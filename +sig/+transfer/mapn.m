function [val, valset] = mapn(net, inputs, node, f)
%SIG.TRANSFER.MAPN Apply values of inputs through mapn function
%   Applies the values of input nodes to a given function and returns the
%   result.  
%   Inputs:
%     net (int) - id of Signals network to whom input nodes belong 
%     inputs (int) - array of input node ids whose values are to be mapped
%       through a function
%     node (int) - id of node whose value is to be assigned the output
%     f (cell) - 2-element cell array of the form {function_handle, output
%       arg position}, where the first element is a handle to the function
%       to be evaluated and the second is the output argument position to
%       be assigned.
%
%   Outputs:
%     val - the value resulting from evaluating function contained in f.
%       Value is assigned to node.
%     valset (logical) - true if all input nodes have a working value and
%       function f{1} has been evaluated
%
%   Example:
%     % Logic for mapping values of nodes 2 and 3 of network 0 through
%     max() and assigning 2nd output arg to node 4 (via mexnet callbacks):
%     val = sig.transfer.mapn(0, [2 3], 4, {@max 2})
%     
% See also sig.node.Signal/applyTransferFun sig.node.Signal/mapn
[f, outnum] = f{:}; % Destructure function
n = numel(inputs);
inpvals = cell(n, 1);
wvset = false(n, 1);
for inp = 1:n
  [wv, wvset(inp)] = workingNodeValue(net, inputs(inp));
  if wvset(inp) % value follows working value first
    inpvals{inp} = wv;
  else % cvset % falls back to current value
    [cv, cvset] = currNodeValue(net, inputs(inp));
    if cvset
      inpvals{inp} = cv;
    else % finding an input with no value set -> no output
      val = [];
      valset = false;
      return
    end
  end
end

if any(wvset)
  % canonical line: call map function with latest inputs. new output(s) are
  % result from map
  out = cell(1,outnum);
  try
    [out{:}] = f(inpvals{:});
    val = out{end};
    valset = true;
  catch ex
    msg = sprintf(['Error in Net %i mapping Nodes [%s] to %i:\n'...
      'function call ''%s'' with inputs (%s) produced an error:\n %s'],...
      net, num2str(inputs), node, func2str(f), ...
      strjoin(mapToCell(@(v)toStr(v,1),inpvals), ', '), ex.message);
    sigEx = sig.Exception('transfer:mapn:error', ...
      msg, net, node, inputs, inpvals, f);
    ex = ex.addCause(sigEx);
    rethrow(ex)
  end
else % no inputs have a working value -> no output
  val = [];
  valset = false;
end

end