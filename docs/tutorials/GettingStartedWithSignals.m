%GETTINGSTARTEDWITHSIGNALS A script for learning how *Signals* works

% todo: add to Part 4
%% Notes:
% Author: Jai Bhagat - j.bhagat@ucl.ac.uk (w/inspiration from Miles Wells
% and Andy Peters)
%
% *Note 1: Before beginning, please make sure that within MATLAB you are
% currently in the 'tutorials' folder containing this file.
% 
% *Note 2: Code files that are mentioned in this file will be written 
% within (not including) closed angluar brackets (<...>). Highlight, 
% right-click and select "Open" or "Help on" to view these code files. 
% Try it out here: <sig.Signal> <sig.Node.Signal> (it may be useful to keep
% these Class files open for reference documentation of *Signals* methods)
%
% *Note 3: It is convenient and sometimes necessary to use anonymous
% functions with some *signals* methods. If you are unfamiliar with using 
% anonymous functions in MATLAB, run 'doc Anonymous Functions' for a MATLAB 
% primer. Similarly, it may also be helpful to understand the basics of 
% object-oriented programming. Run 'doc Object-Oriented Programming' for a
% MATLAB primer.
%
% *Note 4: Along the way, you will encounter questions/assignments for you
% to solve, marked by closed double dashes (--...--). Answers to these 
% questions can be found in the 'Answers' section at the bottom of this 
% file.
%
% -- 1) Who created *signals*? --

%% Intro:
% *Signals* was originally developed in order to create and run simple,
% elegant and flexible stimulus presentation for neurophysiological
% experiments. Principally, *signals* allows for monitoring and 
% manipulating stimuli (and other experimental parameters) over time. This 
% is done by representing each parameter of interest as a signal!
%
% When creating an experiment that will use *signals*, a *signals* network 
% - <sig.Net> - must first be created. Every signal belongs to a 
% *signals* network, and is identifiable in the network by its ID. There
% are two major types of signals: 1) origin signals (<sig.Net.origin> /
% <sig.node.OriginSignal>), which are created directly in/by the
% *signals* network, and upon which all other signals depend, and 
% 2) dependent signals (<sig.Signal> / <sig.node.Signal>), which are 
% created from other signals (first-order dependent signals are created 
% from origin signals).
% *Note: when actually creating a MATLAB function that will run a *signals*
% experiment (referred to as a *signals* "experiment definition", or "exp 
% def"), you will only ever create dependent signals - all origin signals 
% will be created for you by the *signals* framework. After completing this
% tutorial, see the follow-up tutorial, <signalsExpDefTutorial>, for more 
% info on creating an exp def.
%
% In this tutorial you will learn the core features of *signals*. You will 
% 1) create signals within a *signals* network; 2) use common arithmetic and
% and signals-specific functions to manipulate signals; 3) live plot 
% signals to visualise their changes over time; 4) create simple visual
% stimuli using signals. 
%

%% Part 1: Create signals in a *signals* network

% Let's create a signals network and three origin signals:
clear all %#ok<*CLALL> clear all workspace, hidden & global vars that might interfere with *signals* 
net = sig.Net;
os1 = net.origin('os1');
os2 = net.origin('os2');
os3 = net.origin('os3');

% let's create <TidyHandle> variables so we can display the output of
% our signals in the command window whenever they get updated
os1Out = os1.output;
os2Out = os2.output;
os3Out = os3.output;

% all signals initialize with empty values, so let's post to them 
os1.post(1); % our signals can hold single values,
os2.post([0 1 2]); % vectors,
os3.post([1 2 3; 4 5 6; 7 8 9]); % and even arrays

% -- 2) Create a 4th origin signal, 'os4'. Post "Hello, *signals*" to this
% signal, and make sure its output is displayed --

%% Part 2: Create (and manipulate) dependent signals from our origin signals

% Let's use some common MATLAB functions to create new signals from our
% origin signals:
dsAdd = os1 + 1; dsAddOut = dsAdd.output;
dsMult = os3 * os3'; dsMultOut = dsMult.output;
dsNot = not(os2); dsNotOut = dsNot.output;
dsAnd = os2 & os2'; dsAndOut = dsAnd.output; %*note, the short-circuit '&&' and '||' operators do not work on signals
dsGE = os3*-1+10 >= os3; dsGEOut = dsGE.output;

% These dependent signals will also initialize with empty values and do not
% update until the signals they depend on update, so let's help them out by
% re-posting to our origin signals: 
os1.post(1); % first value displayed is 'os1', second is 'dsAdd'
os2.post([0 1 2]); % first value displayed is 'os2', second is 'dsNot', third is 'dsAnd'
os3.post([1 2 3; 4 5 6; 7 8 9]); % first value displayed is 'os3', second is 'dsMult', third is 'dsGE'

% -- 3) Use MATLAB's 'horzcat' function to create a new dependent signal, 
% 'dsStr' from 'os4' to append ", I am a signal" to the value of 'os4'.
% Re-post "Hello, *signals*" to os4, and make sure the output of 'dsStr' is
% displayed. --

% Now let's use some common signal-specific functions to create new signals:
% Let's first clear all our old output signals for clarity's sake, so the
% only display in the command line will be from the new dependent signals
% we will create
clearvars -except net os1 os2 os3

% *Note: In the below examples, the signals-specific functions get used 
% exclusively as signals-object method calls 
% (i.e. 'newSignal = s1.method(s2)'). However, these functions can also be 
% used analagously in a classic functional fashion 
% (i.e. 'newSignal = method(s1,s2)'). Most signals-specific functions were
% written to make use of the former approach because it can be helpful and 
% intuitive to think of these functions as method calls on one signal, with
% other signals as input arguments for the specific method which is called.
% This is why we'll use this approach here, but feel free to use whichever 
% syntax you are most comfortable with.
 
% 'at': 'ds = s1.at(s2)' returns a dependent signal 'ds' which takes the
% current value of 's1' whenever 's2' takes any "truthy" value
% (that is, a value not false or zero).
dsAt = os1.at(os2); ds1At2Out = dsAt.output; %#ok<*NASGU>
os1.post(1);
os2.post(0); % nothing will be displayed
os2.post(2); % '1' will be displayed
os2.post(false); % nothing will be displayed (but value of 'dsAt' remains 1)
clear ds1At2Out

% 'to': 'ds = s1.to(s2)' returns a dependent signal 'ds' which can only
% ever take a value of 1 or 0. 'ds' initially takes a value of 1 when 's1'
% takes a truthy value. 'ds' then alternates between updating to '0'
% the first time 's2' updates to a truthy value after 's1' has updated
% to a truthy value, and updating to '1' the first time 's1' updates
% to a truthy value after 's2' has updated to a truthy value.
dsTo = os1.to(os2); dsToOut = dsTo.output;
os1.post(1); % '1' will be displayed
os1.post(2); % nothing will be displayed
os2.post(1); % '0' will be displayed
os1.post(0); % nothing will be displayed
os1.post(1); % '1' will be displayed
clear dsToOut

% 'map': 'ds = s1.map(f, formatSpec)' returns a dependent signal 'ds' that
% takes the value resulting from mapping function 'f' onto the value
% in 's1' (i.e. 'f(s1)') whenever 's1' takes a value.
f = @(x) x.^2 + x; % the function to be mapped
dsMap = os3.map(f); dsMapOut = output(dsMap);
os3.post([1 2 3]); % '[2 6 12]' will be displayed
clear dsMapOut

% 'scan': 'ds = s1.scan(f, init)' returns a dependent signal 'ds' which
% applies an initial value 'init' to the first element in 's1' via the
% function 'f', and then applies each subsequent element in 's1' to the
% previous element, again via the function 'f', resulting in a running
% total, whenever 's1' takes a value. If 'init' is a signal, it will
% overwrite the current value of 'ds' whenever it updates.
f = @plus;
dsScan = os3.scan(f, 5); dsScanOut = output(dsScan);
os3.post([1 2 3]); % '[6 7 8]' will be displayed
clear dsScanOut

% 'delay': 'ds = s1.delay(n)' returns a dependent signal 'ds' which takes
% as value the value of 's1' after a delay of 'n' seconds, whenever 's1' 
% updates.
dsDelay = os1.delay(2); dsDelayOut = output(dsDelay);
% <sig.Net.runSchedule> is a method that checks for and applies
% updates to signals that are to be updated after a delay.
os1.post(1); pause(2); net.runSchedule; % '1' will be displayed
clear dsDelayOut

% -- 4) 
%      a) Create origin signals, 'expStart', which will signify the start
% of your experiment, and 'newTrial', which will signify the start of each 
% new trial. 
%      b) Create a dependent signal, 'endTrial', which will signify 
% the end of each trial. Make 'endTrial' update to '2' 3 seconds after 
% every 'newTrial'. 
%      c) Create dependent signals 'trialNum', which will signify the 
% current trial number (i.e. update to a new value every time there is a 
% new trial), and 'trialNumFunc', which will return the value of the 
% trial number cubed - 1, each time there is a new trial. 
%      d) Create signals 'trialRunning', a dependent signal which will 
% update to '1' at the start of each new trial and update to '0' at the 
% end of each new trial, an origin signal 'trialStr', whose value will be 
% the string "Trial is Running", and 'dispTrialStr', a dependent signal 
% which will update to 'trialStr' whenever 'trialRunning' updates to '1'.
%      e) Create (TidyHandle) variables that will display the output for 
% all of these signals whenever they get updated.
%
%    Hints: 
%      a) Just create these signals, don't post any values to them.
%      b) Use 'delay' to create 'endTrial' from 'newTrial'.
%      c) Use 'scan' to crerate 'trialNum' from 'newTrial', and use 'map'
% to create 'trialNumFunc' from 'trialNum'
%      d) Use 'to' to create 'trialRunning' from 'newTrial' and 'endTrial'.
% Post the appropriate string to the origin signal 'trialStr' after
% creating it. Use 'at' to create 'dispTrialStr' from 'trialStr' and
% 'trialRunning'.
%      e) use 'output' to create the variables that will display the
% signals' values. --

% Once you've finished 4), run the following block of code, which will
% execute 5 loops (i.e. 5 trials) of your experiment (and note how we only
% explicitly update 'expStart' and 'newTrial' here, because all other
% signals are dependent on these two origin signals):
n = 0;
while n < 5
  if n == 0
    expStart.post('Start Experiment'); % start of experiment
    pause(2);
  end
  newTrial.post(1) % start of new trial (displays output of 'newTrial',
  % 'trialNum', 'trialNumFunc', 'trialRunning', 'dispTrialStr')
  pause(3); % 3 seconds from new trial to end trial
  net.runSchedule; % displays output of 'endTrial', 'trialRunning'
  disp('Trial has Ended');
  pause(1); % pause 1 second betweeen end trial and next new trial
  n = n+1; % trial counter
end
disp('End Experiment');

%% Part 3: Plot signals and visualise their changes over time

% Live-plotting signals is useful to visualise how aspects of your
% experiment are changing over time. When running a *signals* experiment in
% Rigbox, this plotting is done for you via <sig.timeplot>. In the
% following block of code, we will take key aspects of this function to
% implement live-plotting of the signals we've created in 4).

% Let's clear our current workspace and re-create our signals from 4)
clear all
net = sig.Net;
expStart = net.origin('expStart');
newTrial = net.origin('newTrial');
endTrial = newTrial.delay(3)+1;
trialNum = newTrial.scan(@plus, 0);
trialNumFunc = trialNum.map(@(x) x.^3-1);
trialRunning = to(newTrial, endTrial);
trialStr = net.origin('trialStr'); trialStr.post('Trial is Running');
dispTrialStr = trialStr.at(trialRunning);

sigs = StructRef; % Like MATLAB's 'struct', but for signals
% Let's put all our signals from 4) into this <StructRef>
sigs.expStart = expStart; 
sigs.newTrial = newTrial; 
sigs.endTrial = endTrial;
sigs.trialNum = trialNum; 
sigs.trialNumFunc = trialNumFunc; 
sigs.trialRunning = trialRunning;
sigsCell = struct2cell(sigs); % convert to a cell array for plotting
names = fieldnames(sigs); % names of signals 
n = numel(sigsCell); % number of signals

% create our figure and subplots
sigsFig = figure('Name', 'LivePlotExample', 'NumberTitle', 'off'); 
axh = zeros(n,1); % our axes handles for our signal plots
lastVals = cell(n,1); lastVals(:) = {0}; % the last values for all our signals, initialized to 0

% create a colormap to plot our signals
cmap = colormap(sigsFig, 'hsv');
skipsInCmap = length(cmap) / n;
cmap = cmap(1:skipsInCmap:end, :);

loopNum = net.origin('loopNum'); % initialize loop number signal
loopNum.post(1);

% for each signal: create an axis handle, prettify, and add a listener that
% will do the actually plotting of updates
listeners = TidyHandle.empty(n,0); % initialize 'listeners' as a 'TidyHandle' vector
for i = 1:n
  axh(i) = subplot(6,1,i, 'parent', sigsFig);
  hold(axh(i), 'on');
  %x_t{i} = signals{i}.map(...
    %@(x)struct('x',{x},'t',{GetSecs}), '%s(t)');
  curTitle = title(axh(i), names{i}, 'interpreter', 'none');
  listeners(i,1) = onValue(sigsCell{i}, @(val)... % when a signal updates, plot it
    stairs(axh(i), [loopNum.Node.CurrValue-1 loopNum.Node.CurrValue], [lastVals{i}, val],...
    'Color', cmap(i,:), 'Marker', 'o', 'MarkerFaceColor', cmap(i,:)));
end
set(axh, 'XLim', [0 5]);

% Let's run our experiment again
n = 0;
while n < 5
  if n == 0
    expStart.post(1); % start of experiment
    pause(2);
  end
  newTrial.post(1) % start of new trial (displays output of 'newTrial',
  % 'trialNum', 'trialNumFunc', 'trialRunning', 'dispTrialStr')
  pause(3); % 3 seconds from new trial to end trial
  net.runSchedule; % displays output of 'endTrial', 'trialRunning'
  pause(1); % pause 1 second betweeen end trial and next new trial
  lastVals = sigsCell; % save current vals as 'lastVals' for next trial
  loopNum.post(loopNum.Node.CurrValue+1);
  n = n+1; % trial counter
end
disp('End Experiment');

%% Part 4: Create simple visual stimuli using signals

% The ability to simply and intuitively create custom visual stimuli 
% is perhaps *signals* most cherished feature. In this section, we'll cover
% creating a gabor, circle and rectangle. 
%
% we'll use <vis.grating> to create a gabor patch drifting grating
clear all;
net = sig.Net;
t = net.origin('t');
gaborVis = vis.grating(t);

%% Answers:

% % 1) 
% % Chris Burgess!
% 
% % 2) 
% os4 = net.origin('os4');
% os4Out = os4.output;
% os4.post('Hello, *signals*');
% 
% % 3)
% dsStr = horzcat(os4, ', I am a signal');
% dsStrOut = dsStr.output;
% os4.post('Hello, *signals*');
% 
% % 4a) 
% expStart = net.origin('expStart');
% newTrial = net.origin('newTrial');
% 
% % 4b)
% endTrial = newTrial.delay(3)+1;
% 
% % 4c)
% trialNum = newTrial.scan(@plus, 0);
% trialNumFunc = trialNum.map(@(x) x.^3-1);
% % in this case, you could also create 'trialNumFunc' without using 'map':
% % trialNumFunc = trialNum.^3-1;
% 
% % 4d)
% trialRunning = to(newTrial, endTrial);
% trialStr = net.origin('trialStr'); trialStr.post('Trial is Running');
% dispTrialStr = trialStr.at(trialRunning);
% % in this case, we could also combine multiple method calls togethers, and
% % create 'dispTrialStr' without needing to explicitly create 'trialRunning':
% % dispTrialStr - trialStr.at.to(newTrial, endTrial);
% 
% % 4e)
% expStartOut = expStart.output;
% newTrialOut = newTrial.output;
% endTrialOut = endTrial.output;
% trialNumOut = trialNum.output;
% trialNumFuncOut = trialNumFunc.output;
% trialRunningOut = trialRunning.output;
% dispTrialStrOut = dispTrialStr.output;




























