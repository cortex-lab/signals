function [val, valset] = map(net, input, node, f)
%SIG.TRANSFER.MAP Summary of this function goes here
%   Detailed explanation goes here

[wv, wvset] = workingNodeValue(net, input);% assumes one input only
if wvset
  % canonical line: call map function with latest input. new output is
  % result from map
  try
    val = f(wv);
    valset = true;
  catch ex
    msg = sprintf(['Error in Net %i mapping Node %i to %i:\n'...
      'function call ''%s'' with input %s produced an error:\n %s'],...
      net, input, node, func2str(f), toStr(wv,1), ex.message);
    sigEx = sig.Exception('transfer:map:error', msg, net, node, input, wv, f);
    ex = ex.addCause(sigEx);
    rethrow(ex)
  end
else % input has no value -> no output value
  val = [];
  valset = false;
end

end