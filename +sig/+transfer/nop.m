function [val, valset] = nop(net, inputs, node, ~)
% SIG.TRANSFER.NOP Performs no operation 
%   Regardless of inputs, returns as if nothing is set.  This is the
%   default transfer function if none is provided to the sig.node.Node
%   constructor.  It is the equivalent of a 'dead' node where no value will
%   never propagate.
%
%   Inputs:
%     net (int) - id of Signals network to whom input nodes belong.
%     inputs (int) - array of input node ids.
%     node (int) - id of node whose value is to be left unassigned.
%
%   Outputs:
%     val (double) - always empty.
%     valset (logical) - always false.
%
%   Example:
%     % Logic for no operation on input node 1 of network 0 (done in mexnet): 
%     val = sig.transfer.nop(0, 1, 3)
%
% See also sig.node.Node, sig.node.Signal/identity
warning('signals:transfer:nopCalled', 'sig.transfer.nop called')
val = [];
valset = false;

