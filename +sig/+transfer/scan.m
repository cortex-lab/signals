function [val, valset] = scan(net, input, node, funcs)
% SIG.TRANSFER.SCAN Summary of this function goes here
%   Detailed explanation goes here

% always assumes inputs: [item_1, ...., item_n, seed, par_1, ..., par_m]
nElemInps = numel(funcs);
nParInps = numel(input) - nElemInps - 1;

%% deal with a new seed, if any, it will override current value
[seedwv, seedwvset] = workingNodeValue(net, input(numel(funcs)+1));
if seedwvset
  val = seedwv;
  valavail = true;
  valset = true;
else
  % get current node value
  [val, valavail] = currNodeValue(net, node);
  valset = false;
end
%% obtain latest parameter inputs if any
pars = cell(1, nParInps);
for ii = 1:nParInps
  inpidx = numel(funcs) + 1 + ii;
  [parval, parset] = workingNodeValue(net, input(inpidx));
  if ~parset % value follows working value first
    [parval, parset] = currNodeValue(net, input(inpidx));
    if ~parset % scan cannot proceed if a par is missing
      return;
    end    
  end
  pars{ii} = parval;
end
%% deal with a new element, if any
for ii = 1:nElemInps
  [itemwv, itemwvset] = workingNodeValue(net, input(ii));
  if valavail && itemwvset
    % Canonical line: call scan function with current accumulator value (ie
    % current node value) and the new input value. New output is revised
    % accumulator value
    try
      f = funcs{ii};
      val = f(val, itemwv, pars{:});
      valset = true;
    catch ex
      msg = sprintf(['Error in Net %i mapping Nodes [%s] to %i:\n'...
        'function call ''%s'' with inputs (%s) produced an error:\n %s'],...
        net, num2str(input), node, func2str(f), ...
        strjoin(mapToCell(@(v)toStr(v,1), [{val itemwv}, pars]), ', '), ex.message);
      sigEx = sig.Exception('transfer:mapn:error', ...
        msg, net, node, input, [{val itemwv}, pars], f);
      ex = ex.addCause(sigEx);
      rethrow(ex)
    end
  end
end

end
