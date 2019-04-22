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
figh = figure('Name', 'Press ctrl on horizontal grating',...
  'Position', [680 250 560 700], 'NumberTitle', 'off');
vbox = uiextras.VBox('Parent', figh);
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