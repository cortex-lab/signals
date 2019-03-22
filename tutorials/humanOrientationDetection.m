function humanOrientationDetection(t, events, params, visStim, inputs, outputs, audio)
%% Description
% HUMANORIENTATIONDETECTION is an exp def based on:
% Ringach, D. L. “Tuning of Orientation Detectors in Human Vision.” 
% Vision Research 38, no. 7 (April 1998): 963–72.

% In this exp def, a set of 40 different drifting sinusoidal gratings will 
% appear to the user (10 different orientations of [0:20:180] degrees, at 
% each of 4 different phases of [90:90:360] degrees, each with a spatial 
% frequency of 1 cycle/degree, at a presentation rate of 30 Hz). The 
% display of each grating will be chosen uniformly randomly from the set 
% of 40. The user's task is to press the space bar when a horizontal 
% grating (orientation of 0 degrees) is displayed. The experiment lasts 4
% minutes.
%% Running this exp def:
% 1) Run the command: 'expTestPanel = exp.ExpTest;' to launch the
% 'expTestPanel' GUI, and read the 'Usage' section in 'exp.ExpTest' for
% running this exp def within the 'expTestPanel'.
% 2) Afterwards, run the script 'analyzeHOD' to visualize your performance.

% 1) Create a distribution of grating orientations for each of the 30 
% sampled time values (1s in time) that immediately precede a space bar
% press, over the entire experiment. Of the 30 distributions, find the 
% one whose distribution deviates most from uniform*, and ensure the mode 
% of this distribution is at the target orientation (0 degrees)**. The time 
% value associated with this distribution ('T' - i.e. the time before the 
% space bar press) will be set as the user's typical response time. Due to 
% variability in the user's response time over the course of the 
% experiment, calculate a response time window 'T_w' symmetrically around 
% 'T', with window length 'm', where either the distribution of 
% orientations for the upper bound ('T_u' = 'T' + 'm'2), or the lower bound 
% ('T_l' = 'T' - 'm'/2), has the highest possible p-value it can at a 
% significance level of p = .05, when computing whether the distribution 
% is significantly different from the uniform distribution*.
%
% 2) Create unit normalized histogram of distribution of orientations 
% within 'T_w' for each space bar press

% *(Using MATLAB's 'runstest' to test for deviation from uniform, with 
% median value of the distribution as the test's "mu" parameter)
% **(If it's not, throw an error (because the user clearly didn't run
% the task correctly), and ask the user to re-run the experiment) 

oris = 0:20:180; % set of orientations, deg
phases = 90:90:360; % set of phases, deg
presentationRate = 30; % Hz
sf = 1; %spatial frequency, cyc/deg
winlen = 10; % length of histogram window, frames

figh = figure('Name', 'Press ctrl on horizontal grating',...
  'Position', [680 250 560 700], 'NumberTitle', 'off');
vbox = uix.VBox('Parent', figh);
[t, setElemsFun] = sig.playgroundPTB([], vbox);
sigbox = t.Node.Net;
axh = axes('Parent', vbox, 'NextPlot', 'replacechildren', 'XTick', oris);
xlabel(axh, 'Orientation');
ylabel(axh, 'Time (frames)');
ylim([0 winlen] + 0.5);
%% Signals stuff
% Create a signal of WindowKeyPressFcn events from the figure
keyPresses = sigbox.fromUIEvent(figh, 'WindowKeyPressFcn'); 
% Create a filtered version, only keeping Ctrl presses. Turn each into 'true'
reports = keyPresses.keepWhen(strcmp(keyPresses.Key, 'space')).map(true);
% Sample the current time at presentationRate
sampler = skipRepeats(floor(presentationRate*t));
% Randomly sample orientations and phases using sampler
oriIdx = sampler.map(@(~)randi(numel(oris)));
phaseIdx = sampler.map(@(~)randi(numel(phases)));

currOri = oriIdx.map(@(idx)oris(idx));
currPhase = phaseIdx.map(@(idx)phases(idx));
% Create a Gabor with changing orientations and phases
grating = vis.grating(t, 'sinusoid', 'gaussian');
grating.show = true;
grating.orientation = currOri;
grating.phase = currPhase;
grating.spatialFreq = sf;

oriMask = oris' == currOri; % orientation indicator vector
oriHistory = oriMask.buffer(winlen); % buffer last few oriMasks

% Each time there's a subject report, add the oriHistory snapshot to an
% accumulating histogram
histogram = oriHistory.at(reports).scan(@plus, zeros(numel(oris), winlen));
% Plot histogram surface each time it changes
histogram.onValue(@(data)imagesc(oris, 1:winlen, flipud(data'), 'Parent', axh));

%% Add the grating to the renderer
setElemsFun(struct('grating', grating));

