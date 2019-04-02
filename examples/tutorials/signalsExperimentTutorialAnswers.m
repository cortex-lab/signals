% This file contains answers to the questions/assignments in the
% <tutorialSignalsExperiment> file.

% 1) 
% Chris Burgess!

% 2) 
totalReward = reward.scan(@plus, 0); % signal to track total reward

% 3)
% This wouldn't work because this assignment would only evaluate
% 'randi(2)', once, at the start of the experiment, and so 'defaultSide'
% would have the same value for each trial in the experiment

% 4)
incorrectMove = iff(defaultSide ==1, azimuthPos <= -55,...
  azimuthPos >= 55); % signal for incorrect move, (more than 10 visual degrees in wrong direction) 

% 5)
% When using either the '|' or '&' logical operators on signals, the
% resulting signal will only update when all of the signals involved in the
% logical operation update. In this case, we want only one of
% 'correctMove', 'trialTimeout', or 'incorrectMove' to update each trial,
% so 'response' would never take a value.

% 6) Both of these cases would cause infinite recursion because they will
% result in 'endTrial' taking and keeping a value, so 'endTrial' will
% update, which will cause 'newTrial' to update, which will cause
% 'endTrial' to update, etc... What we really want is an "instantaneous"
% update of 'endTrial', which is why we use the 'setTrigger' method

% 7)
audio.default = incorrectInstant.then(0.1*incorrectTone);
audio.default = timeoutInstant.then(0.1*incorrectTone); % we'll use the same 'incorrectTone' for trial timeouts

% 8)
defaultOriLeft = newTrial.map(@(x) randi([0 90]));
defaultOriRight = newTrial.map(@(x) randi([0 90]));

% 9)
leftVisStim = vis.grating(t);
leftVisStim.azimuth = deltaWheel + azimuthDefault;
leftVisStim.orientation = defaultOriLeft; % our signal with the randomly chosen orientation for the left stimulus
leftVisStim.show = interactiveStart.to(endTrial);

rightVisStim = vis.grating(t);
rightVisStim.azimuth = deltaWheel + -azimuthDefault;
rightVisStim.orientation = defaultOriRight; % our signal with the randomly chosen orientation for the right stimulus
rightVisStim.show = interactiveStart.to(endTrial);

