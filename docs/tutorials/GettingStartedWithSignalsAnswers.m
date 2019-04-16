% This file contains answers to the questions/assignments in the
% **GettingStartedWithSignals** tutorial

% 1) 
% Chris Burgess!

% 2) 
os4 = net.origin('os4');
os4Out = os4.output;
os4.post('Hello, *signals*');

% 3)
dsStr = horzcat(os4, ', I am a signal');
dsStrOut = dsStr.output;
os4.post('Hello, *signals*');

% 4a) 
expStart = net.origin('expStart');
newTrial = net.origin('newTrial');

% 4b)
endTrial = newTrial.delay(3)+1;

% 4c)
trialNum = newTrial.scan(@plus, 0);
trialNumFunc = trialNum.map(@(x) x.^3-1);
% in this case, you could also create 'trialNumFunc' without using 'map':
% trialNumFunc = trialNum.^3-1;

% 4d)
trialRunning = to(newTrial, endTrial);
trialStr = net.origin('trialStr'); trialStr.post('Trial is Running');
dispTrialStr = trialStr.at(trialRunning);
% in this case, we could also combine multiple method calls togethers, and
% create 'dispTrialStr' without needing to explicitly create 'trialRunning':
% dispTrialStr - trialStr.at.to(newTrial, endTrial);

% 4e)
expStartOut = expStart.output;
newTrialOut = newTrial.output;
endTrialOut = endTrial.output;
trialNumOut = trialNum.output;
trialNumFuncOut = trialNumFunc.output;
trialRunningOut = trialRunning.output;
dispTrialStrOut = dispTrialStr.output;