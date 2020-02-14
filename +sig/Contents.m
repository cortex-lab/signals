% +SIG All principal classes and functions for implementing the Signals
% framework in MATLAB
%
% Files
%   Exception       - MException object with added info for Signals 
%   gelem           - Generate a simple Gabor patch image
%   Net             - A network for managing Signals nodes
%   quiescenceWatch - Trigger when a signal doesn't change for some period
%   Registry        - Log values of Signals assigned to this
%   Signal          - Interface class for Signals
%   void            - Returns the instance of VoidSignal
%   VoidSignal      - A Singleton class for mocking Signals
%
% Packages
%   test            - Functions for testing and plotting Signals via the
%                     command
%   node            - Implementation of Signals as Node objects
%   scan            - Functions suppoting the Signals scan method
%   transfer        - Transfer functions for implementing various Signals
%                     methods