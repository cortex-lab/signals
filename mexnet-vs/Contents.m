% C Library for Signals.
%  The mexnet folder contains all compiled MEX files required for running
%  Signals in MATLAB.  
% 
%% Contents:
% addNode.mexw64 - 
% applyNodes.mexw64 - 
% clearNodeWorkingValue.mexw64 - 
% createNetwork.mexw64 - 
% currNodeValue.mexw64 - 
% deleteNetwork.mexw64 - 
% deleteNode.mexw64 - 
% network.dll - 
% networkInfo.mexw64 - 
% nodeInputs.mexw64 - 
% setNodeEventTarget.mexw64 - 
% submit.mexw64 - 
% workingNodeValue.mexw64 - 

%% Networks
% A maximum of 10 networks are allowed at any one time
% networks - an array of structs holding nodes defined in network.h
%
% Properties:
% 	nodes - array of Node structs
% 	nNodes - size of network
% 	active - boolean indicating if active
% 	deleteCallback - callback for mexAtExit invocation (via
%                    sqDeleteNetwork)
%

%% Nodes:
% Node struct holding information about network node
%
% Properties:
%   netId - id of parent network
% 	id - unique node id
% 	nTargets - size of target nodes
% 	targets - array of target Node objects
% 	transferer - a Transferer struct instance for this node
%   eventsTarget - call function on target 
% 	inUse - boolean flag indicating whether node is active
% 	appendValues - boolean flag indicating whether to overwrite current
%                  value or append
%   queued - boolean indicating state for appending new values to existing 
%            ones
%   workingValue - working value of node
%   currValue - current value of node
%   currValueAllocElems - elems allocated for mxArray data array

%% Transferer:
% Tranferer struct holding information about node's operations
% 
% Properties:
%   opCode - the operation code
%   funName - the name (char) of the transfer function to call
%   args - the arguments to call the function with (4 in total)
%   workingInputChanges - boolean to flag that inputs have changed due to
%                         unapplied transactions
%   targetIndices - the index into the target that each input goes to
%   targetFields - the field in the target that each input goes to

%% Network functions
% applied = sqApply(net, nodes, list)
%  Applies values of given nodes (triggers transfer functions)
%  Called by applyNodes()
%
% sqDispNetwork(net)
%  Prints number of nodes present in network `net`
%  Called by networkInfo()
%
% sqDispNode(net, node)
%   Prints parameters of `node` in `net`
%   Called by networkInfo()
%
% sqAddNode(net, inputs, nInputs, transferer, appendValues)
%   Adds a new node to `net` with given parameters
%   Called by addNode()
%
% sqSetNodeEventsTarget(net, node, target)
%   Set event target callback(?)
%   Called by setNodeEventsTarget()
%
% sqSetNodeWorkingValue(net, node, value)
%   Sets working value of `node` in `net`
%   Called by clearNodeWorkingValue()
%   Called by addNode(), transact()
%
% sqDeleteNetwork(net)
%   Deletes network `net` and executes delete callback (if any)
%   Called by sqDeleteNetworks(), deleteNetwork()
%
% sqDeleteNetworks()
%   Deletes all networks
%   Callback to mexAtExit (set by createNetwork())
%   Called by deleteNetwork()
%
% value = sqGetNodeCurrValue(net, node)
%   Retrieves current value of `node` in `net`
%   Called by currNodeValue()
%
% value = sqGetNodeWorkingValue(net, node)
%   Retrieves working value of `node` in `net`
%   Called by workingNodeValue()
%
% sqDeleteNode(net, node)
%   Delete `node` in `net`
%   Called by deleteNode()
%
% sqGetNodeInputs(net, node)
%   Get inputs for `node` in `net`
%   Called by nodeInputs()
%
% sqSetNodeInputs(net, node, inputs)
%   Set inputs for `node` in `net`
%   Called by nodeInputs()
%
% sqTransact(net, node, value)
%   Apply `value` to `node` in `net`
%   Called by submit()
%
% transact(net, node, value)
%   Set working node value, apply transfer function and queue downstream
%   nodes
%   Called by sqTransact()
%% FAQ
% Q: Why did you choose C (Matrix API) over C++ (Data API)?
%
% Q: The delete callback in createNetwork appears to be used in
% sqDeleteNetwork whereby it tries to call a MATLAB function 'apply' with a
% pointer to the callback function.  This doesn't work.  Why not simply
% call the callback as in the examples?
%
% Q: Why do I see 0 is not a valid network id?
% A: Perhaps line 82 of network.c is the culprit?
%
% Q: What's up with currNodeValue mess.  Remove copy value flag?