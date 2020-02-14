function [structVal, inpNodes, fieldIdxs, structIdxs] = flattenSignalStruct(blueprint)
%FLATTENSIGNALSTRUCT Flattens a struct of mixed value type
%  Provided a blueprint structure whose fields contain one or more Signals,
%  returns a new struct along with node ids and indicies for setting field
%  values.  This function is called by the underlying mexnet.
%
%  Inputs:
%   blueprint (struct) : The structure to be flattened.  May be non-scalar.
%
%  Outputs:
%   structVal (struct) : an initial structure made from flattening the
%     blueprint.  All fields that are Signals in the blueprint are empty.
%   inpNodes (int) : a list of node IDs that can update the structure
%   fieldIdxs (int) : linear index of field that each input node updates
%   structIdxs (int) : linear index into structure that each input node updates
%
% See also sig.node.Signal/flattenStruct

fieldNames = fieldnames(blueprint);
bpdatasz = [numel(fieldNames) size(blueprint)];
vals = cell(bpdatasz);
bpvals = struct2cell(blueprint);
isSig = cellfun(@isaSignal, bpvals);
% the values of blueprint fields that aren't signals set immediately
vals(~isSig) = bpvals(~isSig);
% get nodes from blueprint fields that are signals
sigs = bpvals(isSig);
sigidx = find(isSig);
inpNodes = zeros(1, numel(sigs)); % IDs of nodes
fieldIdxs = zeros(1, numel(sigs)); % Index of field
structIdxs = zeros(1, numel(sigs)); % Index of non-scalar struct array
for si = 1:numel(sigs)
  n = node(sigs{si}); % Get node
  inpNodes(si) = n.Id; % Get ID from node
  [fieldIdxs(si), structIdxs(si)] = ind2sub(bpdatasz, sigidx(si)); % Get indicies
end
% make the value structure that will take signal values as they come
structVal = cell2struct(vals, fieldNames);

end
%% Helper function
function b = isaSignal(v)
b = isa(v, 'sig.node.Signal');
end

