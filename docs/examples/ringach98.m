%% Tuning of orientation detectors in human vision
% Ringach, DL. (1998) Vision Research 38(7): 963-72
% https://doi.org/10.1016/S0042-6989(97)00322-2
%
% This script replicates the above psychophysics experiment using Signals.
% When play is pressed the experiment begins and a sequence of gratings of
% different orientations are presented in quick succession.  The subject
% must press the ctrl key as quickly as possible each time a chosen
% orientation is observed (i.e. vertical, horizontal or oblique).  As the
% subject does this the chosen orientations are plotted as a histogram.
% The observered distribution follows a 'Mexican hat' shape.

%% Parameters
oris = 0:18:162; % set of orientations, deg
phases = 90:90:360; % set of phases, deg
presentationRate = 10; % Hz
sf = 0.2; %spatial frequency, cyc/deg
winlen = 10; % length of histogram window, frames

%% Figure window
% Create a figure to plot histogram of responses
scrnSz = get(groot, 'ScreenSize'); % Get screen resolution
figPos = [scrnSz(3)-560, scrnSz(4)-780, 560 700]; % Pick a reasonable position
figh = figure('Name', 'Press ctrl on vertical grating',...
  'Position', figPos, 'NumberTitle', 'off'); % Create the figure

% Create a container for the play/pause button and axes
vbox = uix.VBox('Parent', figh);
% Create a new Psychtoolbox stimulus window and renderer, returns a timing
% Signal and function to load our visual elements
[t, setElemsFun] = sig.test.playgroundPTB(vbox);
sigbox = t.Node.Net; % Handle to the Signals Network object

% Create our axes for the histogram
axh = axes('Parent', vbox, 'NextPlot', 'replacechildren', 'XTick', oris);
xlabel(axh, 'Orientation');
ylabel(axh, 'Time (frames)');
ylim([0 winlen] + 0.5);
vbox.Heights = [30 -1]; % 30 px for the button, the rest for the plot

%% Signals stuff
% Create a signal of WindowKeyPressFcn events from the figure
keyPresses = sigbox.fromUIEvent(figh, 'WindowKeyPressFcn'); 
% Create a filtered version, only keeping Ctrl presses. Turn each into 'true'
reports = strcmp(keyPresses.Key, 'control');
% Sample the current time at presentationRate
sampler = skipRepeats(floor(presentationRate*t));
% Randomly sample orientations and phases using sampler
oriIdx = sampler.map(@(~)randi(numel(oris)));
phaseIdx = sampler.map(@(~)randi(numel(phases)));

currOri = oriIdx.map(@(idx)oris(idx));
currPhase = phaseIdx.map(@(idx)phases(idx));
% Create a Gabor with changing orientations and phases
grating = vis.grating(t, 'sinusoid', 'gaussian');
grating.show = true; % Make it visible
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