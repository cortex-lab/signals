function [val, valset] = flatten(net, inputs, thisId, state)
% SIG.TRANSFER.FLATTEN Tranfer the value in the Node held by the input
%   If the value of the main input (the 'director' node) is a Signal,
%   extract its node id (the 'source' node) and return its value.  If the
%   director's value is not a Signal object, simply return that.  Assumes
%   inputs are [director, source]:
%     1) source connection will change when director changes
%     2) as source values change this node value will change to match it
%
%   Inputs:
%     net (int) - id of Signals network to whom input nodes belong.
%     inputs (int) - array of input node ids: [director, source].
%     thisId (int) - id of node whose value is to be assigned the output.
%     state (StructRef) - holds a 'unappliedInputChanges' flag that is true
%       when director has new working value.
%
%   Outputs:
%     val (*) - the director's value if set and not a Signal, otherwise the
%       source's value if set.  Value is assigned to `thisId`.
%     valset (logical) - true if the director's working value is a Signal
%       with a value set, or if the director's value has changed.
%
%   Example:
%     % Logic for returning value of node 3 held in value of node 2 of
%     % network 0  (done in mexnet): 
%     val = sig.transfer.keepWhen(0, [2 3], struct('unappliedInputChanges', 0))
%
% See also sig.node.Signal/applyTransferFun sig.node.Signal/flattenStruct

valset = false; val = [];

%%% read director - if changed, rewire source connection as appropriate
[dirval, dirset] = workingNodeValue(net, inputs(1)); 
if dirset %new/working director value
  state.unappliedInputChanges = true;
  valset = true;
  if updateSource(dirval) % director is a signal, we'll take our value from it later
    val = [];
  else % director is a normal value, so set out value to it and return
    val = dirval;
    return % we're done
  end
else %no working director value
  if state.unappliedInputChanges % previous connection modification must be undone
    state.unappliedInputChanges = false;
    [dirval, dirset] = currNodeValue(net, inputs(1)); 
    if dirset % current value exists for director, so use it
      val = [];
      if ~updateSource(dirval) % director is a normal value, so no source input to check
        return % we're done, just fall back to our current value
      end
    else % no current director value, so output unset
      nodeInputs(net, thisId, inputs(1)); % no source input
      val = [];
      return % we're done
    end
  end
end

%%% read source, if any
if numel(inputs) > 1
  [sourceval, sourceset] = workingNodeValue(net, inputs(2));
  if sourceset % new working value on source so our new working value takes that
    valset = true;
    val = sourceval;
  elseif valset 
    % new source connection was made earlier, so our new current value
    % should take its current value
    [val, sourceset] = currNodeValue(net, inputs(2));
    if ~sourceset
      valset = false;
    end
  end
end

%%% helper function
  function isSig = updateSource(dirval)
    if isa(dirval, 'sig.node.Signal') % director value is a signal...
      inpNode = node(dirval); % ...so get its node
      inputs = [inputs(1) inpNode.Id];
      nodeInputs(net, thisId, inputs); %...and set it as our source input
      isSig = true;
    else % director value is just a value, so no source input
      nodeInputs(net, thisId, inputs(1));
      isSig = false;
    end
  end
end