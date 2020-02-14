% setNodeEventTarget.m Help file for setNodeEventTarget MEX-file.
%  setNodeEventTarget.mex64 - Compiled C MEX
%
%  Call valueChanged method of target each time node value updates. 
%    
%  Inputs: 
%    network id (int)
%    node id (int)
%    target (sig.Signal)
%
%  Outputs:
%    N/A
%
%  The calling syntax is:
%    setNodeEventTarget(netID, nodeID, eventTarget)
%
%  Examples:
%     % Display value when node updates
%     signal = origin(sig.Net, 'node');
%     signal.OnValueCallbacks = {@disp}; % Protected property
%     setNodeEventTarget(node.Net.Id, node.Id, signal)
%
%     % Remove event target callback
%     setNodeEventTarget(node.Net.Id, node.Id, [])
%
%  Errors:
%     sq:notEnoughArgs - Incorrect number of input arguments
%     
%  Created with:
%  MATLAB (R2019a)
%  Platform: mexw64 (win64)
%  Microsoft Visual C++ 2019 (C)
%
%  This is a MEX file function for Signals.
%
% See also mexnet-vs folder for source code
