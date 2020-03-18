function [val, valset] = buffer(net, inputs, node, ~)
%SIG.TRANSFER.BUFFER Apply values of inputs through mapn function
%   Adds value of first input node to array of values held by node.
%   Always assumes input nodes = [newSample, maxSamples].
%
%   Inputs:
%     net (int) - id of Signals network to whom input nodes belong
%     inputs (int) - array of input node ids whose values are to be mapped
%       through a function
%     node (int) - id of node whose value is to be assigned the output
%
%   Outputs:
%     val (*) - the updated buffer value resulting from concatination.
%       Value is assigned to node.
%     valset (logical) - true if the first input node has a working value.
%
%   Example:
%     % Logic for buffering values of node 2 up to the value of node 3 in 
%     % network 0 and assigning output to node 4 (via mexnet callbacks):
%     val = sig.transfer.buffer(0, [2 3], 4)
%
% See also sig.node.Signal/applyTransferFun sig.node.Signal/buffer
valset = false; val = [];

% obtain latest buffer size, if any
[maxSamps, wvset] = workingNodeValue(net, inputs(2));
if ~wvset % value follows working value first
  [maxSamps, wvset] = currNodeValue(net, inputs(2));
  if ~wvset % buffer cannot proceed if a maxSamps is missing
    return;
  end
end

% get current node value, i.e buffer
buff = currNodeValue(net, node);
% get new value to append to buffer 
[newval, wvset] = workingNodeValue(net, inputs(1));
if wvset
  try
    free = size(buff, 2) - maxSamps;
    if free >= 0 % if no free slots left in buffer...
      % drop oldest samples and cat new value
      val = cat(2, buff(:,free+2:end), newval);
    else % otherwise append new value to buffer
      val = [buff newval];
    end
    valset = true;
  catch ex
    msg = sprintf(['Error in Net %i mapping Nodes [%s] to %i:\n'...
      'Concatinating %s to %s produced an error:\n %s'],...
      net, num2str(inputs), node, toStr(newval,1), toStr(buff,1), ex.message);
    sigEx = sig.Exception('transfer:buffer:error', ...
      msg, net, node, inputs, {buff, newval}, @horzcat);
    ex = ex.addCause(sigEx);
    rethrow(ex)
  end
end