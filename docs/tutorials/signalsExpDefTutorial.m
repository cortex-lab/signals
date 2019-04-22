function signalsExpDefTutorial(t, events, params, visStim, inputs, outputs, audio)
%SIGNALSEXPDEFTUTORIAL *Signals* Experiment Definition Tutorial

% todo: mention repeating incorrect trials?
%% Notes:
% Author: Jai Bhagat - j.bhagat@ucl.ac.uk (w/inspiration from Miles Wells
% and Andy Peters)

% *Note 1: Before beginning, please make sure that within MATLAB you are
% currently in the 'tutorials' folder containing this file.

% *Note 2: Code files that are mentioned in this file will be written 
% within (not including) closed angluar brackets (<...>). Highlight, 
% right-click and select "Open" or "Help on" to view these code files. 
% Try it out here: <sig.Signal> <sig.Node.Signal> (it may be useful to keep
% these Class files open for reference documentation of *Signals* methods)

% *Note 3: When installing Rigbox, you should have installed all required
% dependencies, so at this time make sure you have the latest versions of
% Psychtoolbox (psychtoolbox.org/download) and GUI layout toolbox
% (mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) 
% installed.

% *Note 4: It is convenient and sometimes necessary to use anonymous
% functions with some *signals* methods. If you are unfamiliar with using 
% anonymous functions in MATLAB, run 'doc Anonymous Functions' for a MATLAB 
% primer. Similarly, it may also be helpful to understand the basics of 
% object-oriented programming. Run 'doc Object-Oriented Programming' for a
% MATLAB primer.

% *Note 5: Along the way, you will encounter questions/assignments, some of
% which you MUST solve in order to create a functional Exp Def. These will 
% be marked by closed double dashes (--...--). Answers to these questions 
% can be found in the 'Answers' section at the bottom of this file.
%
% -- 1) Who created *signals*? --

%% Intro:
% Welcome to this tutorial on running a *Signals* Experiment Definition
% (also referred to as an "Exp Def" or "*Signals* Protocol") within Rigbox. 
% For an introduction to *Signals* before running an experiment, open 
% <GettingStartedWithSignals>. In this tutorial, we will go step-by-step
% to create a version of the "Burgess Steering Wheel Task" the CortexLab 
% uses to probe rodent behaviour and decision-making. (See 
% 1) https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5603732/pdf/main.pdf and
% 2) https://www.ucl.ac.uk/cortexlab/tools/wheel for more information on
% this task). 
%
% In this tutorial we will 1) define the experiment and discuss the
% *Signals* Exp Def input arguments; 2) create a first version of the task,
% where a visual stimulus will appear on the left, and will have to be
% moved (via virtual link to a steering wheel) to center to result in a 
% reward; 3) create a second version of the task where the stimuli can now
% appear on either left or right, and will have to be moved to center to
% result in a reward; 4) create a third version of the task where two
% stimuli will appear on both left and right simultaneously, and 
% certain properties of the stimuli will dictate which one has to be moved
% to center to result in a reward; 5) create task parameters that can be
% changed in real-time during the experiment.

%% Part 1: Define a *Signals* experiment:
%
% *Signals* structures experiments in trials: each trial continues
% indefinitely until an experimenter defined end trial occurs. An
% experimenter defines an end trial as when some condition is met (e.g. a 
% correct move is made, an incorrect move is made, a certain duration 
% elapses, etc...). As soon as the end trial condition has been met, the
% next new trial starts.
%
% For this experiment, we will create our own version of the Burgess
% Steering Wheel Task: a visual stimulus will be presented to a subject
% and the subject will have to turn a wheel to move the visual stimulus 
% to the center of its environment to get a water reward from a reward
% valve. 
%
% To see how this experiment can be created in a *Signals* Exp Def, let's 
% first go over the Exp Def input arguments.
%
% Exp Defs are functions defined as: 
% 'ExpDef(t, events, params, visStim, inputs, outputs, audio)'. (This file
% is an Exp Def). Just as with any MATLAB function, these input arguments 
% can be named anything, the only requirement is the order of the arguments 
% (e.g. 'events' could be named 'evts').
%
% 't' - This is the origin signal ( <sig.Net/origin> / 
% <sig.node.OriginSignal> ) that will track time during the experiment.
% *Signals* will create this (along with a few other initial origin 
% signals) at experiment onset.
%
% 'events' - This is a <sig.Registry> object (which is a subclass of 
% <sig.StructRef>, essentially a MATLAB 'struct' for signals) containing
% the signals to be saved when the experiment ends. It contains by default 
% the origin signals *Signals* creates at experiment onset (these are
% 'events.expStart', 'events.expStop', 'events.newTrial', and 
% 'events.trialNum' -the roles of these signals should be obvious by name-) 
% plus new signals added to it by the experimenter (e.g. 
% 'events.correctTrial').
%
% 'params' - This is a <sig.SubscriptableSignal> object that *Signals* 
% turns into a Struct, containing experimenter defined parameters as
% signals, which will be used during the experiment. These parameters will
% be given a default value, but can be changed by the experimenter in 
% real-time during the experiment.
%
% 'visStim' - This is a <sig.StructRef> object containining fields as
% signals that define the visual stimuli that will be presented during
% the experiment. 
%
% 'inputs' - This is a <sig.Registry> object containing hardware inputs as 
% signals. It contains by default the wheel as 'inputs.wheel'.
%
% 'outputs' - This is a <sig.Registry> object containing hardware outputs
% as signals. It contains by default the reward valve as 'outputs.reward'.
%
% 'audio' - This is an <audstream.Registry> object (similar to
% <sig.Registry>, but specifically for audio stimuli) containing fields as
% signals that define the audio stimuli that will be presented during the
% experiment. This object also contains a field, 'Devices', which contains
% information about the actual audio device(s) that emit the audio stimuli.
%
% *Signals* structures experiments in trials,
% *Note: 'events', 'params', 'inputs', and 'outputs' are all saved by
% default in a 'block' .mat file when the experiment ends.

%% Part 2: First version of task
% % Comment out all other sections and uncomment this section.
% 
% % *Note: Remember, every Exp Def is given the origin signals 'events.expStart',
% % 'events.expStop', 'events.newTrial', and 'events.trialNum', so all 
% % additional signals an experimenter defines in their Exp Def will be
% % built off of these origin signals. Additionally, an Exp Def must contain
% % an 'events.endTrial' signal, which *signals* will use to start the next
% % new trial, as soon as 'events.endTrial' takes a value to signify the end 
% % of the current trial.
% 
% % In general, a rough format for building Exp Defs is in the following
% % order:
% % 1) Define 'inputs', 2) Lay-out the experiment and trial framework, 
% % 3) Define 'visStim' 4) Define 'audio', 5) Define 'outputs', 6) Add to 
% % 'events', 7) (Optional) Add 'params'
% 
% % We'll take this general approach as we go through this tutorial. We'll
% % skip adding parameters until the final part of this tutorial.
% 
% % 1) Let's start this Exp Def by setting the 'inputs' (i.e. the wheel) and 
% % an interactive phase for each trial (i.e. when the rodent will be allowed 
% % to turn the wheel). And so we don't confuse ourselves with extra dot 
% % notation, let's set our own 'newTrial' and 'trialNum' from the 'events' 
% % structure. We'll typically build all of our signals off of these two 
% % origin signals.
% 
% newTrial = events.newTrial;
% trialNum = events.trialNum;
% interactiveStart = newTrial.delay(1); % signal defining interactive period (where wheel can be moved) 1 s after a new trial starts (see <sig.Signal/delay> for more info)
% wheel = inputs.wheel; % signal for wheel, only updates when wheel moves
% wheel0 = wheel.at(interactiveStart); % signal that gets wheel value at onset of each trial (see <sig.Signal/at> for more info)
% deltaWheel = 1/3 * (wheel - wheel0); % signal for how much wheel has moved within a trial, scaled down by a factor of 3 
% 
% % 2) Let's layout the experiment and trial framework:
% % Let's define the default azimuth for the visual stimulus at trial onset
% % and define a correct trial as azimuth=0 (when the visual stimulus is 
% % moved to the center) 
% 
% azimuthDefault = newTrial.then(-45); % signal for azimuth at start of each new trial (45 degrees left of center)
% azimuthPos = deltaWheel + azimuthDefault; % signal for current azimuth position (i.e. how much wheel has moved azimuth since start of trial)
% correctMove = azimuthPos >= 0; % signal for correctly moving stim to center
% reward = interactiveStart.setTrigger(correctMove); % signal for reward only at first time of correct move (see <sig.Signal/setTrigger> for more info)
% 
% % -- 2) Using the 'scan' method, insert a variable 'totalReward' that
% % tracks the total reward delivered in this session (i.e. it adds 1 to its
% % value each time 'reward' updates) --
% 
% % *Note: 'endTrial' ends the trial and 'expStop' stops the experiment, 
% % respectively, whenever they take a value, regardless of whether that 
% % value is truthy or not (e.g., if 'expStop' updates to 0, the experiment
% % will stop). So, we can't just assign logical expressions to either of
% % these signals (e.g. 'expStop = trialNum > 10') b/c logical expressions 
% % update every cycle in the reactive network. We will learn the reason
% % why these two signals are still "activated" even when updating to
% % non-truthy values when we get to implementing parameters in the last part
% % of this tutorial
% 
% endTrial = interactiveStart.setTrigger(reward); % signal to end trial when reward is given, but only after each new interactive trial phase
% stop = trialNum>10; % signal to end experiment (after 10 trials)
% expStop = stop.then(1);
% 
% % 3) Let's create the visual stimulus, link its azimuth to the wheel,
% % and assign it to 'visStim'.
% % *Note, somewhat unintuitively, we have to do this *after* defining the
% % azimuth for the visual stimulus (as we did above), since we first 
% % needed to define the azimuth position for a correct trial
% 
% firstVisStim = vis.grating(t); % signal as gabor patch grating (see <vis.grating> for more info)
% firstVisStim.azimuth = deltaWheel + azimuthDefault; % signal to link azimuth to wheel 
% firstVisStim.show = interactiveStart.to(endTrial); % signal to display the stimulus only during trial interactive phase (see <sig.Signal/to> for more info)
% visStim.first = firstVisStim; % store this visual stimulus in our visStim StructRef
% 
% % 4) Let's create an auditory stimulus that will signify the trial 
% % interactive phase
% 
% audioDev = audio.Devices('default'); % assign computer's default audio device to the <audstream.Registry> object
% onsetTone = aud.pureTone(1000, 0.25, audioDev.DefaultSampleRate, 0.1,...
%   audioDev.NrOutputChannels); % create onset tone (see <aud.pureTone> for more info)
% audio.default = interactiveStart.then(0.1*onsetTone); % signal that actually plays onsetTone at start of trial interactive phase
% 
% % 5) Let's set the 'outputs' (i.e. the reward valve)
% 
% outputs.reward = reward.then(1);
% 
% % 6) Let's add to the 'events' structure the signals that we want to plot
% % and save
% 
% events.endTrial = endTrial; % must ALWAYS define 'events.endTrial'
% events.expStop = expStop;
% events.interactiveStart = interactiveStart;
% events.deltaWheel = deltaWheel;
% events.reward = reward;
% events.totalReward = totalReward;
% 
% % *Note: at this point, we have used all the input arguments in the Exp Def
% % besides 'params'. This will remain the case for the next two versions of
% % the task we'll create, until we get to the final section of this
% % tutorial.
% %
% % To run this Exp Def, follow the instructions in the 'ReadMe' file in
% % this folder.

%% Part 3: Second version of task
% % Comment out all other sections and uncomment this section.
% 
% % In this section, we'll build off of our first version of the task, and
% % create a second version in which the visual stimulus can now appear on
% % either left or right side, and will have to be moved appropriately to
% % center.
% %
% % We'll also define incorrect trials, and create an auditory
% % stimuli for incorrect trials.
% 
% % 1) The inputs will be the same as in the previous section
% 
% newTrial = events.newTrial;
% trialNum = events.trialNum;
% interactiveStart = newTrial.delay(1); 
% wheel = inputs.wheel; 
% wheel0 = wheel.at(interactiveStart);
% deltaWheel = 1/3 * (wheel - wheel0);
% 
% % 2) Let's repeat some of our experiment and trial framework from the
% % previous section, but now define the azimuth of the visual stimulus to
% % appear randomly on either the left or right side at the start of every
% % trial. Let's also define an incorrect trial when the wheel moves a small
% % amount in the incorrect direction, and define the end of a trial as 
% % either a) after a correct move, b) after an incorrect move, or c) after
% % some duration. 
% 
% defaultSide = newTrial.map(@(x) randi(2)); % signal for randomly assigning side vis stim appears on (see <sig.Signal/map> for more info)
% 
% % -- 3) Why wouldn't the following assignment for 'defaultSide' work?
% % defaultSide = randi(2); --
% 
% azimuthDefault = iff(defaultSide == 1, interactiveStart.then(-45),... 
%   interactiveStart.then(45)); % signal for default vis stim position at start of each trial: left if 'defaultSide'=1, right otherwise
% azimuthPos = deltaWheel + azimuthDefault;
% correctMove = iff(defaultSide == 1, azimuthPos >= 0, ...
%   azimuthPos <= 0); % signal for correct move, which depends on vis stim starting position (see <iff> for more info)
% reward = interactiveStart.setTrigger(correctMove);
% totalReward = reward.scan(@plus, 0);
% trialTimeout = (t - t.at(interactiveStart)) > 3; % signal indicating trial end if more than 3 seconds from start of interactive phase
% timeoutInstant = interactiveStart.setTrigger(trialTimeout); % signal indicating the instant at which the trial timed out
% 
% % -- 4) Following the syntax for 'correctMove', insert a variable
% % 'incorrectMove' that updates to 1 if the wheel moves the stimulus'
% % azimuth more than 10 degrees in the wrong direction, for either side the
% % stimulus is presented on (i.e. if 'azimuthPos' <= -55 for left presented
% % stimulus, and if 'azimuthPos' >= 55 for right presented stimulus) -- 
% 
% incorrectInstant = interactiveStart.setTrigger(incorrectMove); % signal indicating the instant of the incorrect move
% response = (correctMove+trialTimeout+incorrectMove) > 0; % signal that updates to '1' whenever 1 of 3 trial end possibilities occurs
% endTrial = interactiveStart.setTrigger(response); % signal to end trial when a response occurs
% 
% % -- 5) Why wouldn't the following assignment for 'response' work?
% % response = correctMove | trialTimeout | incorrectMove;
% 
% % -- 6) Why wouldn't the following assignments for 'endTrial' work?
% % endTrial = response.then(1); --
% % endTrial = cond(correctMove, 1, trialTimeout, 1, incorrectMove, 1) (see <cond> for more info)
% 
% stop = trialNum > 10;
% expStop = stop.then(1);
% 
% % 3) The visual stimulus will be the same as in the previous section
% 
% secondVisStim = vis.grating(t);
% secondVisStim.azimuth = deltaWheel + azimuthDefault;
% secondVisStim.show = interactiveStart.to(endTrial);
% visStim.second = secondVisStim;
%  
% % 4) Let's add auditory stimuli signifying correct and incorrect trials
% 
% % The 'onsetTone' is the same as in the previous section
% audioDev = audio.Devices('default');
% onsetTone = aud.pureTone(1000, 0.25, audioDev.DefaultSampleRate, 0.1,...
%   audioDev.NrOutputChannels);
% audio.default = interactiveStart.then(0.1*onsetTone);
% 
% % The 'rewardTone' has a higher pitch than the 'onsetTone' and is shorter
% % in duration
% rewardTone = aud.pureTone(3000, 0.1, audioDev.DefaultSampleRate, 0.01,...
%   audioDev.NrOutputChannels);
% audio.default = reward.then(0.1*rewardTone);
% 
% % The 'incorrectTone' will be a noise burst and 2x as long in duration
% % as 'rewardTone'
% incorrectTone = randn(audioDev.NrOutputChannels,... 
%   0.2 * audioDev.DefaultSampleRate); % generate noise burst via 'randn'
% 
% % -- 7) Following the syntax for the reward tone, create one signal that
% % will play the 'incorrectTone' the instant of an incorrect move, and a
% % second signal that will play the 'incorrectTone' the instant of a trial
% % timeout --
%  
% % 5) The 'outputs' remain the same as in the previous section
% 
% outputs.reward = reward.then(1);
%  
% % 6) Let's add to the 'events' structure the signals that we want to save
% 
% events.endTrial = endTrial;
% events.expStop = expStop;
% events.interactiveStart = interactiveStart;
% events.defaultSide = defaultSide; % add 'defaultSide' to 'events'
% events.deltaWheel = deltaWheel;
% events.correctMove = correctMove;
% events.reward = reward;
% events.totalReward = totalReward;
% events.incorrectMove = incorrectMove; % add 'incorrectMove' to 'events'
% events.trialTimeout = trialTimeout; % add 'trialTimeout' to 'events'
% 
% % To run this version of the Exp Def, follow the instructions in the 
% % 'ReadMe' file in this folder.

%% Part 4: Third version of task
% % Comment out all other sections and uncomment this section.
% 
% % In this section, we'll build off of the second version of the task, and
% % create a third version in which two visual stimuli will appear
% % simultaneously on left and right side, and based on some property of the
% % stimuli, one will have to be moved to center to get a reward.
% 
% % 1) The inputs will be the same as in the previous section
% 
% newTrial = events.newTrial;
% trialNum = events.trialNum;
% interactiveStart = newTrial.delay(1); 
% wheel = inputs.wheel; 
% wheel0 = wheel.at(interactiveStart);
% deltaWheel = 1/3 * (wheel - wheel0);
% 
% % 2) Let's repeat some of our experiment and trial framework from the
% % previous section, but now define the stimulus to be moved to the center
% % as the grating which has an orientation closer to 0 degrees. We'll define
% % the orientation for each grating to be a random integer between 0 and 90
% % (degrees), and if the orientations are equal, we'll pair reward with
% % moving the left stimulus to center.
% 
% % -- 8) Following the example of 'defaultSide' in the previous section, use
% % 'newTrial.map...' to create two signals, 'defaultOriLeft' and
% % 'defaultOriRight' that will randomly take a value between 0 and 90 each
% % new trial --
% 
% % we'll define the default azimuth with a negative value (for the left
% % stimulus), so whenever we are working with the right stimulus, we must
% % use the negative of this value (which will be a positive value)
% azimuthDefault = newTrial.then(-30); % we'll set the azimuth default closer to 0 so we can see both stimuli more clearly
% azimuthPos = deltaWheel + azimuthDefault;
% stimToMove = iff(defaultOriLeft <= defaultOriRight, 1, 2); % signal for which stimulus to move to center (1 for left, 2 for right)
% correctMove = iff(stimToMove==1, azimuthPos >= 0,... 
%   azimuthPos <= 0); % signal for correct move, which depends on stimuli orientations
% reward = interactiveStart.setTrigger(correctMove);
% totalReward = reward.scan(@plus, 0);
% trialTimeout = (t - t.at(interactiveStart)) > 3; 
% timeoutInstant = interactiveStart.setTrigger(trialTimeout);
% incorrectMove = iff(stimToMove==1,... 
%   azimuthPos <= azimuthDefault - 15,...
%   azimuthPos >= -azimuthDefault + 15); % signal for incorrect move, (more than 15 visual degrees in wrong direction) 
% incorrectInstant = interactiveStart.setTrigger(incorrectMove);
% response = (correctMove+trialTimeout+incorrectMove) > 0; 
% endTrial = interactiveStart.setTrigger(response);
% stop = trialNum > 10;
% expStop = stop.then(1);
% 
% % 3) Now we will create two visual stimuli, one for the left and the other
% % for the right side
% 
% % -- 9) Following the examples of creating visual stimuli in the previous
% % sections, create two stimuli, 'leftVisStim' and 'rightVisStim' using
% % 'vis.grating(t)'. Set the 'azimuth', 'orientation', and 'show' properties
% % appropriately for these two stimuli, based on this version of the task
% 
% % and let's assign both stimuli to our 'visStim' StructRef
% visStim.left = leftVisStim; visStim.right = rightVisStim;
% 
% % 4) The auditory stimuli will be the same as in the previous section
% 
% % onset tone
% audioDev = audio.Devices('default');
% onsetTone = aud.pureTone(1000, 0.25, audioDev.DefaultSampleRate, 0.1,...
%   audioDev.NrOutputChannels);
% audio.default = interactiveStart.then(0.1*onsetTone);
% 
% % reward tone
% rewardTone = aud.pureTone(3000, 0.1, audioDev.DefaultSampleRate, 0.01,...
%   audioDev.NrOutputChannels);
% audio.default = reward.then(0.1*rewardTone);
% 
% % incorrect tone
% incorrectTone = randn(audioDev.NrOutputChannels,... 
%   0.2 * audioDev.DefaultSampleRate); 
% audio.default = incorrectInstant.then(0.1*incorrectTone);
% audio.default = timeoutInstant.then(0.1*incorrectTone);
% 
% % 5) The 'outputs' remain the same as in the previous section
% 
% outputs.reward = reward.then(1);
%  
% % 6) Let's add to the 'events' structure the signals that we want to save
% 
% events.endTrial = endTrial;
% events.expStop = expStop;
% events.interactiveStart = interactiveStart;
% events.stimToMove = stimToMove;
% events.defaultOriRight = defaultOriRight; % add 'defaultOriRight' to 'events'
% events.defaultOriLeft = defaultOriLeft; % add 'defaultOriLeft' to 'events'
% events.deltaWheel = deltaWheel;
% events.correctMove = correctMove;
% events.reward = reward;
% events.totalReward = totalReward;
% events.incorrectMove = incorrectMove;
% events.trialTimeout = trialTimeout; 
% 
% % To run this version of the Exp Def, follow the instructions in the 
% % 'ReadMe' file in this folder.

% Part 5: Fourth version of task and using parameters
% Comment out all other sections, and uncomment this section.

% In this section, we'll build off of the third version of the task, and
% create a fourth and final version in which the visual stimuli will vary
% in orientation and contrast, but only contrast will be important in 
% determining which stimulus is paired with reward. We will use 'params' to 
% manipulate these properties of the visual stimuli in real-time.

% The following notes are important to consider when adding 'params', to
% an Exp Def:
%
% The signals contained in 'params' are the parameters the experimenter 
% defines in their Exp Def. These parameters will appear as editable fields 
% in the *Signals* experiment GUI (either the "MC Panel" or the 
% "ExpTestPanel", depending on which one the experimenter is using). The 
% experimenter can click on any parameter in the GUI during experiment 
% runtime, change that parameter's value, and the new value will be 
% assigned to that parameter on the next trial. 
%
% Each parameter can either be global or conditional: Global parameters are 
% used in every trial of the experiment; conditional parameters are used
% "conditionally" on a subset of the total number of trials. During the
% experiment, global parameters can be made conditional, and vice versa,
% via push buttons in the GUI. The GUI itself will contain one panel named
% "Global", containing the global parameters, and another panel named 
% "Conditional", containing the conditional parameters. In this Exp Def, 
% we'll define the grating orientation as a global parameter, and the 
% grating contrast as a conditional parameter.
%
% Somewhat unintuitively, we must assign 'params' to variables before
% posting values to 'params'. E.g:
%
% 'x = params.x; params.x = 1;' instead of: 'params.x = 1; x = params.x'
%
% This is because if we do the latter, 'x' will hold an empty value 
% (instead of 1) because it is a dependent signal (on 'params.x'), and all 
% dependent signals initialize with empty values - they only update after
% the signal they depend on updates. (See Section 'Part 2' in
% <GettingStartedWithSignals> if this is unclear).

% 1) The inputs will be the same as in the previous section

newTrial = events.newTrial;
trialNum = events.trialNum;
interactiveStart = newTrial.delay(1); 
wheel = inputs.wheel; 
wheel0 = wheel.at(interactiveStart);
deltaWheel = 1/3 * (wheel - wheel0);

% 2) Let's repeat some of our experiment and trial framework from the
% previous section, but now define trials in which only the grating with
% higher contrast will be paired with reward (or the left grating if the 
% contrast for both visual stimuli are equal), and that stimulus must be
% moved to center. We'll pluck the orientation and contrast for the stimuli
% from the parameters we define at the end of this Exp Def. 

defaultOriLeft = params.LeftVisStimOrientation;
defaultOriRight = params.RightVisStimOrientation;
defaultContrastLeft = params.LeftVisStimContrast;
defaultContrastRight = params.RightVisStimContrast;

azimuthDefault = newTrial.then(-30);
stimToMove = iff(defaultContrastLeft >= defaultContrastRight, 1, 2);
correctMove = iff(stimToMove==1, (deltaWheel + azimuthDefault) >= 0,... 
  (deltaWheel + -azimuthDefault) <= 0);
reward = interactiveStart.setTrigger(correctMove);
totalReward = reward.scan(@plus, 0);
trialTimeout = (t - t.at(interactiveStart)) > 3;
timeoutInstant = interactiveStart.setTrigger(trialTimeout);
incorrectMove = iff(stimToMove==1,... 
  (deltaWheel + azimuthDefault) <= (azimuthDefault - 15),...
  (deltaWheel + -azimuthDefault) >= (-azimuthDefault + 15)); 
incorrectInstant = interactiveStart.setTrigger(incorrectMove);
response = (correctMove+trialTimeout+incorrectMove) > 0; 
endTrial = interactiveStart.setTrigger(response);
stop = trialNum > 10;
expStop = stop.then(1);

% 3) Now we will create the two visual stimuli, plugging in the signals for
% orientation and contrast we defined in the parameters

leftVisStim = vis.grating(t);
leftVisStim.azimuth = deltaWheel + azimuthDefault;
leftVisStim.orientation = defaultOriLeft; % our signal with the randomly chosen orientation for the left stimulus
leftVisStim.contrast = defaultContrastLeft;
leftVisStim.show = interactiveStart.to(endTrial);

rightVisStim = vis.grating(t);
rightVisStim.azimuth = deltaWheel + -azimuthDefault;
rightVisStim.orientation = defaultOriRight; % our signal with the randomly chosen orientation for the right stimulus
rightVisStim.contrast = defaultContrastRight;
rightVisStim.show = interactiveStart.to(endTrial);

visStim.left = leftVisStim; visStim.right = rightVisStim;

% 4) The auditory stimuli will be the same as in the previous section

% onset tone
audioDev = audio.Devices('default');
onsetTone = aud.pureTone(1000, 0.25, audioDev.DefaultSampleRate, 0.1,...
  audioDev.NrOutputChannels);
audio.default = interactiveStart.then(0.1*onsetTone);

% reward tone
rewardTone = aud.pureTone(3000, 0.1, audioDev.DefaultSampleRate, 0.01,...
  audioDev.NrOutputChannels);
audio.default = reward.then(0.1*rewardTone);

% incorrect tone
incorrectTone = randn(audioDev.NrOutputChannels,... 
  0.2 * audioDev.DefaultSampleRate); 
audio.default = incorrectInstant.then(0.1*incorrectTone);
audio.default = timeoutInstant.then(0.1*incorrectTone);

% 5) The 'outputs' remain the same as in the previous section

outputs.reward = reward.then(1);
 
% 6) Let's add to the 'events' structure the signals that we want to save

events.endTrial = endTrial;
events.expStop = expStop;
events.interactiveStart = interactiveStart;
events.stimToMove = stimToMove;
events.defaultOriRight = defaultOriRight; 
events.defaultOriLeft = defaultOriLeft; 
events.defaultContrastRight = defaultContrastRight; % add 'defaultContrastRight' to 'events'
events.defaultContrastLeft = defaultContrastLeft; % add 'defaultContrastLeft' to 'events'
events.deltaWheel = deltaWheel;
events.correctMove = correctMove;
events.reward = reward;
events.totalReward = totalReward;
events.incorrectMove = incorrectMove;
events.incorrectInstant = incorrectInstant;
events.trialTimeout = trialTimeout; 
events.timeoutInstant = timeoutInstant;

% 7) Let's now add parameters to our Exp Def. Parameters are typically
% written at the end of an Exp Def in a 'try...catch...end' statement to
% allow for exception handling. 

try
  % Vis Stim Orientation as global parameters assigned to 'params'
  params.LeftVisStimOrientation = 30; % signal that sets the left grating orientation to 30 degrees
  params.RightVisStimOrientation = 60; % signal that sets the right grating orientation to 60 degrees
  
  % Vis Stim Contrast as conditional parameters assigned to 'params':
  % Conditional parameters are defined in Exp Defs as having number of
  % columns > 1, where each column is a condition. All conditional parameters
  % must have the same number of columns.
  params.LeftVisStimContrast = [1 0.75 0.5 0.25 0]; % signal as a vector of possible values for left grating contrast
  params.RightVisStimContrast = [0 0.25 0.5 0.75 1]; % signal as a vector of possible values for right grating contrast
catch ex
  disp(getReport(ex))
end

% To run this version of the experiment, follow the instructions in the
% 'ReadMe' file in this folder. Additionally, while the experiment is 
% running, try editing the parameter values for both grating orientation 
% (in the "Global" panel) and grating contrast (in the "Conditional" panel) 
% by clicking on them directly in the GUI. Feel free to add additional 
% parameters to this Exp Def after you are comfortable - check the stimulus 
% parameters in <vis.grating> to see all the visual stimuli properties you 
% could add/edit as *Signals* parameters.

%% Congratulations!

% You have made it to the end of this tutorial! Hopefully this exercise has
% provided you with a foundation for creating and running your own
% *Signals* Experiments. There is a learning curve to using *Signals*, but
% the vast scope and flexibility in experimental design that *Signals* 
% allows for is well worth the cost (and keep in mind that less than half
% of the all signals-specific functions defined in <sig.Signal> were used
% in this tutorial). Please feel free to contact the author with any
% questions regarding this tutorial, or *Signals* in general!

%% Answers:

% % 1) 
% % Chris Burgess!
% 
% % 2) 
% totalReward = reward.scan(@plus, 0); % signal to track total reward
% 
% % 3)
% % This wouldn't work because this assignment would only evaluate
% % 'randi(2)', once, at the start of the experiment, and so 'defaultSide'
% % would have the same value for each trial in the experiment
% 
% % 4)
% incorrectMove = iff(defaultSide ==1, azimuthPos <= -55,...
%   azimuthPos >= 55); % signal for incorrect move, (more than 10 visual degrees in wrong direction) 
% 
% % 5)
% % When using either the '|' or '&' logical operators on signals, the
% % resulting signal will only update when all of the signals involved in the
% % logical operation update. In this case, we want only one of
% % 'correctMove', 'trialTimeout', or 'incorrectMove' to update each trial,
% % so 'response' would never take a value.
% 
% % 6) Both of these cases would cause infinite recursion because they will
% % result in 'endTrial' taking and keeping a value, so 'endTrial' will
% % update, which will cause 'newTrial' to update, which will cause
% % 'endTrial' to update, etc... What we really want is an "instantaneous"
% % update of 'endTrial', which is why we use the 'setTrigger' method
% 
% % 7)
% audio.default = incorrectInstant.then(0.1*incorrectTone);
% audio.default = timeoutInstant.then(0.1*incorrectTone); % we'll use the same 'incorrectTone' for trial timeouts
% 
% % 8)
% defaultOriLeft = newTrial.map(@(x) randi([0 90]));
% defaultOriRight = newTrial.map(@(x) randi([0 90]));
% 
% % 9)
% leftVisStim = vis.grating(t);
% leftVisStim.azimuth = deltaWheel + azimuthDefault;
% leftVisStim.orientation = defaultOriLeft; % our signal with the randomly chosen orientation for the left stimulus
% leftVisStim.show = interactiveStart.to(endTrial);
% 
% rightVisStim = vis.grating(t);
% rightVisStim.azimuth = deltaWheel + -azimuthDefault;
% rightVisStim.orientation = defaultOriRight; % our signal with the randomly chosen orientation for the right stimulus
% rightVisStim.show = interactiveStart.to(endTrial);


end