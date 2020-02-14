% +TEST A set of convenience functions for playing with Signals
%   The +test sub-package contains functions for playing with Signals
%   outside of a real experiment.  These functions are useful for quickly
%   creating origin signals, visual stimuli and live plots.
%
% Files
%   create        - Returns a set of origin signals
%   sequence      - Creates a sequence signal from an array
%   playground    - <DEPRECATED> Use playgroundPTB
%   playgroundPTB - Creates a stimulus window for playing with Signals
%   plot          - Plot values of two signals against each other
%   timeplot      - Plot values of signals against time
%
% Examples
%   %% Create a new Signals network and add some signals to the network
%   net = sig.Net;
%   input = net.origin('input Signal');
%   dependent = input^2;
%   h = output(dependent);
%   input.post(2)
% 
%   %% Plot some signals live using the command window
%   % Create a Signal that updates with new values every 0.05 seconds
%   x = sig.test.sequence(0:0.1:10, 0.05);
%   x.Name = 'x'; % Call it 'x' in the plot
%   y = cos(x * pi); % Create a dependent Signal
%   sig.test.timeplot(x, y, 'mode', [0 2]); % Plot each variable against time
% 
%   %% Show a visual stimulus using command prompt
%   import sig.test.playgroundPTB
%   import sig.test.timeplot
%   PsychDebugWindowConfiguration
% 
%   [t, setgraphic] = playgroundPTB();
%   vs = StructRef; % Structure to hold our visual elements
% 
%   grating = vis.grating(t); % we want a Gabor grating patch
%   grating.phase = 2*pi*t*3; % with its phase cycling at 3Hz
%   grating.show = true;
%   vs.grating = grating;
%   setgraphic(vs); % render