%% Description:
% ANALYZEHOD is a script that analyzes a user's performance after they
% have run the 'humanOrientationDetection' exp def.

% 1) Load in a block file pertaining to 'humanOrientationDetection'. Check
% to see if the file does indeed come from running
% 'humanOrientationDetection', if not, throw error.

% 2) From the loaded data:
% Create a distribution of grating orientations for each of the 30 
% sampled time values (1 s in time) that immediately precede a space bar
% press, over the entire experiment. Of the 30 distributions, find the 
% one whose distribution deviates most from uniform*, and ensure the mode 
% of this distribution is at the target orientation (0 degrees)**. The time 
% value associated with this distribution ('T' - i.e. the time before the 
% space bar press) will be set as the user's typical response time. 

% 3) Due to variability in the user's response time over the course of the 
% experiment, calculate a response time window 'T_w' symmetrically around 
% 'T', with window length 'm', where either the distribution of 
% orientations for the upper bound ('T_u' = 'T' + 'm'2), or the lower bound 
% ('T_l' = 'T' - 'm'/2), has the highest possible p-value it can at a 
% significance level of p = .05, when computing whether the distribution 
% is significantly different from the uniform distribution*.

% 4) Create unit normalized histogram of distribution of orientations 
% within 'T_w' for each space bar press

% *(Using MATLAB's 'runstest' to test for deviation from uniform, with 
% median value of the distribution as the test's "mu" parameter)
% **(If it's not, throw an error (because the user clearly didn't run
% the task correctly), and ask the user to re-run the experiment) 

%% Get data from block file

%% Get 'T'

%% Get 'T_w' and data within 'T_w' preceding each space bar press

%% Create histogram

%% Get distribution