function humanOrientationDetection(t, events, params, visStim, inputs, outputs, audio)
%% Description
% HUMANORIENTATIONDETECTION is an exp def based on:
% Ringach, D. L. “Tuning of Orientation Detectors in Human Vision.” 
% Vision Research 38, no. 7 (April 1998): 963–72.

% In this exp def, a set of 40 different drifting sinusoidal gratings will 
% appear to the user (10 different orientations of [0:20:180] degrees, at 
% each of 4 different phases of [90:90:360] degrees, each with a spatial 
% frequency of 0.1 cycle/degree, at a presentation rate of 20 Hz). The 
% display of each grating will be chosen uniformly randomly from the set 
% of 40. The user's task is to press the 'response key' when a horizontal 
% grating (orientation of 0 degrees) is displayed. The experiment lasts 4
% minutes.

%% Running this exp def:
% 1) Run the command: 'expTestPanel = exp.ExpTest;' to launch the
% 'expTestPanel' GUI, and read the 'Usage' section in 'exp.ExpTest' for
% using the GUI.
% 2) Afterwards, run the script 'analyzeHOD' to visualize your performance.

%% Creating the signals
responseKey = 'g'; % key for indicating user response
oris = 0:18:162; % set of orientations, deg
phases = 90:90:360; % set of phases, deg
presentationRate = 20; % Hz
sf = 0.1; %spatial frequency, cyc/deg
winLen = 15; % length of histogram window, frames

% get the handle to the ExpTestPanel figure, and create a signal from
% keyboard spacebar events
etph = findobj('Type', 'Figure', 'Name', 'ExpTestPanel'); 
anyKeyPress = t.Node.Net.fromUIEvent(etph, 'WindowKeyPressFcn');
responseKeyPress = anyKeyPress.keepWhen(strcmp(anyKeyPress.Key, responseKey)).map(true);

% Sample the current time at presentationRate
sampler = skipRepeats(floor(presentationRate*t));

% Randomly sample orientations and phases using sampler
oriIdx = sampler.map(@(~) randi(numel(oris)));
phaseIdx = sampler.map(@(~) randi(numel(phases)));
currOri = oriIdx.map(@(idx) oris(idx));
currPhase = phaseIdx.map(@(idx) phases(idx));

% Create a drifting grating with changing orientations and phases
grating = vis.grating(t, 'sinusoid', 'gaussian');
grating.show = events.newTrial.to(responseKeyPress);
grating.orientation = currOri;
grating.phase = currPhase;
grating.spatialFreq = sf;

% add the grating to the visual stimulus handler
visStim.stim = grating; 

% get the orientations of the last 'winLen' number of gratings
oriMask = oris' == currOri; % orientation indicator vector
oriHistory = oriMask.buffer(winLen); % buffer last few oriMasks

% end the trial after the spacebar is pressed
endTrial = responseKeyPress.delay(0.5);

% stop experiment when there have been 100 presses
totalKeyPresses = responseKeyPress.scan(@plus, 0);
stop = totalKeyPresses > 100;

%% Plot the orientation history at spacebar click
% get monitor screensize for setting location of figure
gr = groot;
scrnSz = gr.ScreenSize([3,4]);
histFigName = sprintf(['Histogram of last %d orientations for each "%s" key '...
'press'], winLen, responseKey); 
% set figure name and position (to upper right-hand corner of screen)
histFig = figure('Name', histFigName, 'NumberTitle', 'off',...
  'Position', [scrnSz(1)-560, scrnSz(2)-500, 560 420]);
histFigAx = axes('Parent', histFig, 'NextPlot', 'replaceChildren',...
  'XTick', oris, 'XTickLabel', cellstr(num2str(oris')), 'XLim', [0 162]);

% Each time there's a 'responseKey' press, add the 'oriHistory' snapshot to
% an accumulating histogram
histogram = oriHistory.at(responseKeyPress).scan(@plus,... 
  zeros(numel(oris), winLen));
histogram.onValue(@(data) imagesc(oris, 1:winLen, flipud(data'),... 
  'Parent', histFigAx));

%% add to the 'events' structure the signals we want to save
events.endTrial = endTrial;
events.expStop = stop.then(1);
events.t = t;
events.responseKeyPress = responseKeyPress;
events.sampler = sampler;
events.currOri = currOri;
events.histogram = histogram;
