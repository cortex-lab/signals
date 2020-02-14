function driftingGrating(t, evts, pars, stimuli, ~, ~, ~)
% DRIFTINGGRATING A simple drifting grating flashed during each trial
%   This experiment definition shows one way to create a drifting grating
%   in Signals.

grating = vis.grating(t); % we want a gabor grating patch
grating.phase = 2*pi*t*3; % with its phase cycling at 3Hz
% stimOff occurs some user defined seconds after new trial starts
stimOff = evts.newTrial.delay(pars.stimDuration);
% next trial should start 1s after stimOff
evts.endTrial = stimOff.delay(1);
% stimulus visible between trial onset & stimOff
grating.show = evts.newTrial.to(stimOff);

stimuli.grating = grating;


