% MEXNET C Library for Signals.
% Version xxx 13-Sep-2019
%  The mexnet folder contains all compiled MEX files required for running
%  Signals in MATLAB.  
% 
% Files:
% network.dll - Library file for Signals
% network.mex64 - Signals network functions (not called directly by MATLAB)
% createNetwork.mexw64 - Creates a new Signals network
% networkInfo.mexw64 - Prints network or node information to command window
% addNode.mexw64 - Adds node to a given network
% nodeInputs.mexw64 - Retrieve or set inputs for a given node
% setNodeEventTarget.mexw64 - Call valueChanged method of target each time node value updates
% submit.mexw64 - Applies value to a given node
% applyNodes.mexw64 - Computes values of dependent nodes using working value
% currNodeValue.mexw64 - Retrieves current value of a given node
% workingNodeValue.mexw64 - Retrieves working value of a given node
% clearNodeWorkingValue.mexw64 - Set working value of a given node to null
% deleteNode.mexw64 - Deletes node from a given network
% deleteNetwork.mexw64 - Deletes one all all networks
