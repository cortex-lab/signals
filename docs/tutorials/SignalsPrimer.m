%% Signals Test Script - Introduction
% The purpose of this script is to introduce Signals, how to wire a network
% and a few of the important functional methods associated.  Later, the
% structure of a Signals Experiment will be introduced.

%% Network architecture
% Every signal is part of a network, managed through a 'sig.Net' object.
% The network object holds all the ids of all the signals' nodes.  (FIXME Note 1 about underlying code)

% Every signal has an underlying node; a sig.node.Node object that contains
% a number of important properties:
% Net: a handle to the parent network (sig.Net)
% Inputs: an array of input nodes
% Id: an integer ID used by the low level C code
% NetId: an integer ID for the parent network, used by the low level C code
% CurrValue: the current value that the node holds

net = sig.Net; % Create a new signals network

%% Origin signals
% An origin signal is a special sub-class of the sig.node.Signal class
% whose value can be updated directly using the post method. The function
% call for creating an origin signal takes two inputs: the parent network 
% and optionally, a string identifier.
%
% These origin signals are the input nodes to the reactive network. All
% other signals are either directly or indirectly dependent on origin
% signals. Origin signals can take values of any type, as demonstrated 
% below.
%
% In the context of a Signals Experiment, the origin signals would be the
% timing signal and signals representing hardware devices (a wheel, lever, 
% keyboard, computer mouse, etc...).  These origin Signals should be
% defined outside of your experiment definition function and be input
% variables.  More on this later. 

% You can post values to an origin Signal by using the post method.  This
% is not possible with other classes of Signals as their values instead
% depend on the values of their input nodes. 

% It is worth noting that every Signal has a Name property which may be set
% manually or be be set based on its inputs.  The name of a Signal may be
% used by visualization functions to describe its functional relationship
% within the network.  The name property of an origin Signal is set as
% its second input.  Signals are handle objects and therefore may
% be assigned to any variable name.  Hence there are two means to identify
% a Signal: it's true name (the string held in the Name property) and the
% name of the variable or variables to which it is assigned. Below a Signal
% whose name is 'input' is created and assigned to the variable
% 'originSignal'.  Two values are posted to it, first a double, then a char
% array.

originSignal = net.origin('input'); % Create an origin signal
originSignal.Node.CurrValue % The current value is empty

post(originSignal, 21) % Post a new value to originSignal
originSignal.Node.CurrValue % The current value is now 21

post(originSignal, 'hello') % Post a new value to originSignal
originSignal.Node.CurrValue % The current value is now 'hello'

% You can see there are two names for this signal.  The string identifier
% ('input') is the Signal object's name, stored in the Name property:
disp(originSignal.Name)

% Any Signals derived from this will include this identifier in their Name
% property (an example will follow shortly).  The variable name
% 'originSignal' is simply a handle to the Signal object and can be changed
% or cleared without affecting the object it references (See Note 1 at
% bottom of script).

% Although the value is stored in the Node's CurrValue field, it is not
% intended that you use this field directly.  Doing so will most likely
% lead to unexpected behaviour.

%% Demonstration on sig.Signal/output() method
% The output method is a useful function for understanding the relationship
% between signals.  It simply displays a signal's output each time it takes
% a value.  The output method returns an object of the class TidyHandle,
% which is like a normal listener handle, however when it's lifecyle ends
% it will delete itself.  What this means is that when the handle is no
% longer referenced anywhere (i.e. stored as a variable), the callback will
% no longer function.
net = sig.Net; % Create a new signals network
clc % Clear previous output for clarity

simpleSignal = net.origin('simpleSignal');
h = output(simpleSignal);
class(h)

simpleSignal.post(false)
simpleSignal.post(true)

%% Relationships between signals
% Once you have one or more inputs to the network you can start to build a
% reactive network.  Most of MATLAB's elementary operators work with
% Signals objects in the way you would expect, as demonstrated below.

net = sig.Net; % Create a new signals network
x = net.origin('x'); % Create an origin signal
a = 5; b = 2; c = 8; % Some constants to use in our equation
y = a*x^2 + b*x + c; % Define a quadratic relationship between x and y

ax = sig.plot(x,y,'b-');
xlim(ax, [-50 50]);

for i = -50:1:50
  pause(0.05)
  x.post(i)
end

%%
% TODO example using sin & pi
x = net.origin('x'); % Create an origin signal
y = cos(x * pi);
sig.timeplot(x, y, 'mode', [0 2]);

for i = 0:0.1:10
  pause(0.05)
  x.post(i)
end

% Let's imagine you needed a Signal that showed the angle of its input
% between 0 and 360 degrees:
x = net.origin('x');
y = iff(x > 360, x - 360*floor(x/360), x);

ax = sig.plot(ax, x, y, 'b-');
xlim([0 1080]); ylim([0 360])

for i = 1:4:1080
  pause(0.005)
  x.post(i)
end

%% Logical operations
% Note that the short circuit operators && and || are not implemented in
% Signals
x = net.origin('x'); % Create an origin signal
bool = x >= 5 & x < 10; 

ax = sig.plot(ax, x, bool, 'bx');
xlim(ax, [0 15]), ylim(ax, [-1 2])

for i = 1:15
  x.post(i)
end

%% mod, floor, ceil
x = net.origin('x'); % Create an origin signal

even = mod(floor(x), 2) == 0;
odd = ~even;

ax = sig.timeplot(x, even, odd, 'tWin', 1);
for i = 1:15
  x.post(i)
end

%% Arrays
% You can create numerical arrays and matricies with Signals in an
% intuitive way.  NB: Whenever you perform an operation on one or more
% Signals objects, always expect a new Signals object to be returned.  In
% the below example we create a 1x3 vector Signals, X, which is not an
% array of Signals but rather a Signal that carries a numrical array as its
% value
x = net.origin('x'); 
X = [x 2*x 3];
X_sz = size(X);

h = [output(X), output(X_sz)];

x.post(5)

%% Matrix arithmatic
Xt = X';
Y = X.^3 ./ 2;

% For a full list see doc sig.Signal.  NB: Sometimes due to limitations of
% syntax, it's necessary to do away with syntactic sugar.  It is therefore
% worth remembering the basic functions, i.e. not(), plus(), times(), etc.

%% A note about Signals variables
% Signals are objects that constantly update their values each time the
% Signals they depend on update.  A Signal will not a take a value post-hoc
% after a new Signal takes a value.  Consider the following:
x.Node.CurrValue
y = x^2;
y.Node.CurrValue
x.post(3)
y.Node.CurrValue

% In the context of an experiment, the experiment definition function is
% run once to set up all Signals, before any inputs are posted into the
% network.  More on this later.  % FIXME: clarify

% Likewise if you re-define a Signal, any previous Signals will continue
% using the old values and any future Signals will use the new values,
% regardless of whether the variable name is the same.
y = x^2;
a = y + 2;
y = x^3; % A new Signal object is assigned to the variable y
b = y + 2;

% Looking at the name of your Signals may help you here
% TODO use visualizations (sig.Visualizer)
y.Name
a.Name
b.Name

%% Signals can derive from multiple signals
% The above examples show how a signal can derive from one other signal;
% however, a signal can be defined by any number of other signals, as well
% as by constants.
% Mathematically, Signals can be viewed as variables which, any time they
% take a new value, cause any equations dependent equations to be
% re-evaluated.

% Create some origin signals to post to
x = net.origin('x'); 
a = net.origin('a');
b = net.origin('b');
c = net.origin('c');

y = a*x^2 + b*x + c;
% upperBound = max([abs(a), abs(b), abs(c)]) / abs(a) * (1 + sqrt(5))/2;

sig.timeplot(x, a, b, c, y);

x.post(1), pause(1)
a.post(pi), pause(1)
b.post(3), pause(1)
c.post(8), pause(1)

a.post(5)

%% Indexing with Signals
A = net.origin('A');
h = output(A);
a = A(2); % index a and assign to b
B = A(5:end);
A.post(1:10); % assign a vector of values from 1 to 10

a.Node.CurrValue % 2
B.Node.CurrValue % [5 6 7 8 9 10]

% An index may be another Signal:
i = net.origin('index'); % Define a new Signal 
a = A(i);
A.post(1:10);
i.post(5);
A.post(10:20);

% The selectFrom method allows for indexing from a list of Signals whose
% values may be of different types (in some ways comparable to indexing to
% a cell array):
A = net.origin('A');
B = net.origin('B');
C = net.origin('C');

y = i.selectFrom(A, B, C);
h = output(y);
sig.timeplot(i, A, B, C, y);

A.post('helloSignal'), B.post([1 2 3]), C.post(pi)
i.post(2)
i.post(1)

% When the index is out of bounds the Signal simply doesn't update
i.post(4)

% The indexOfFirst method returns a Signal with the index of the first
% true predicate in a list of Signals.  This has a similar functionality to
% find(arr, 1, 'first'):
idx = indexOfFirst(A > 5, B < 1, C == 5); % FIXME Find a good example


%% Use more complex functions with map
% It is not possible to call all functions with signals objects as inputs,
% and therefore expressions like fliplr(A), where A is a Signal will cause
% an error:
A = net.origin('A'); % Create an origin signal
B = fliplr(A); % Conversion to logical from sig.node.Signal is not possible

% Instead we can use the function map, which will call a given function
% with a Signal's current value as its input each time that signal takes a
% new value
B = A.map(@fliplr);
A.post(eye(5));

% Sometimes your Signal must be in a different positional argument:
% delta = A.map(@(A)diff(A,1,2)); % Take 1st order difference over 2nd dimension
a = A.map(@(A)sum(A,2)); % Take sum over 2nd dimension
A.post(magic(3));

% fun.partial can be a convenient way to map a function when there are a
% number of constant variables in a function:
f = fun.partial(@sprintf, '%.1f%%'); % Returns a function handle which will call sprintf with the first argument as '%.1f%%' 
class(f)
y = x.map(f);
% y = x.map(@(num)sprintf('%.1f%%',num));
y1 = map(100-x, f);
h = [output(y) output(y1)];

x.post(58.4)

% rndDraw = map(evts.newTrial, @(~) sign(rand-0.5)); 

% TODO for more complex anonymous function
% In the following example the response type is 
% timeOutTracker = responseType.bufferUpTo(1000);
% timeOutCount = timeOutTracker.map(@(x) sum(x(find([1 x~=0],1,'last'):end)==0));


% Sometimes you want to derive a Signal whose value is always constant but
% nevertheless updates depending on another Signal, thus acting as a
% trigger for something.  This can be achieved by using a constant value
% instead of a function in map.  For example here we produce a signal that
% is always mapped to true and updates whenever its dependent value
% updates
updated = x.map(true);
% NB c.f. with at, then and skipRepeats
y = net.origin(y);
updatedAndTrue = x.at(y.map(true));
updatedAndTrue = x.at(y > 3);
h = output(updatedAndTrue);

% Note that if the input arg is a value rather than a function handle, it
% is truely constant, even if it's the output of a function:
c = x.map(rand);
rnd = x.map(@(~)rand);
% The tilda here means that the value of Signal x is ignored, instead of
% being assigned to a temporary variable or being mapped into the functon
% rand, thus rand is called with no arguments.

%% Map multiple Signals through a function with mapn
% Mapn takes any number of inputs where the last argument is the function
% that the other arguments are mapped to.  The arguments may be any
% combination of Signals and normal data types.  It's important to note
% that the below 'dot notation' only works if the first input is a
% Signal, otherwise you must use the traditional syntax e.g. mapn(5, A, @f)
B = A.mapn(n, 1, @repmat); % repmat(A,n,1)

% NB: Map will only assign the first output argument of the function to the
% resulting Signal

%% More complex conditionals
% Above we saw how logical operations work with Signals. These can also be
% used in conditional statements that alter the value or operation on a
% given Signal.  For example, to construct something similar to an if/else
% statement, we can use the iff method:
x = net.origin('x');
y = iff(x.map(@ischar), x.map(@str2num), x);

% In order to construct if/elseif statements we use the cond method, where
% the input arguments are predicate-value pairs, for example:
% y = cond(x > 5) FIXME

% As with all Signals, the condition statement is re-evaluated when any of
% its inputs update.  Any input may be a Signal or otherwise, and if no
% predicate evaluates as true then the resulting Signal does not update.

% Likewise, the condition statement will terminate if any of the source
% Signals of a particular pred-value pair do not yet have values.  Also, in
% the same way as a traditional if-elseif statement, each predicate is only
% evaluated so long as the previous one was false.  For this reason, the
% order of pred-value pairs is particularly important. Below we use true as
% the last predicate to ensure that the resulting Signal always has a
% value.
y = cond(...
  x > 0 & x < 5, a, ...
  x > 5, b, ...
  true, c);

%% Demonstration of scan
% Scan is a very powerful method that allows for mapping a signal's current
% value and it's previous value through a function.  This allows for
% defining Signals that have some sort of history to them.
%
% Below we take the value of x and return a value that is the accumulation
% of x by using scan with the function plus.  The third argument to scan
% here is the initial, or 'seed', value.  Because the seed is zero, the
% first time x takes a value, scan maps zero and the value of x
% respectively to the plus function and assigns the output to Signal y.
% The second time x updates, scan maps the current value of y, our
% accumulated value, and the new value of x to the plus function.  

net = sig.Net;
x = net.origin('x');

y = x.scan(@plus, 0); % plus(y, x)

sig.timeplot(x, y, 'tWin', 0.5);
for i = 1:10
  x.post(1)
end

%% The seed value may be a signal
% As with other Signals methods, any of the inputs except the function
% handle may be a Signal.  This is particularly useful as the seed value
% can act as a reset of the accumulator as demonstrated below.

x = net.origin('x');
seed = net.origin('seed');
y = x.scan(@plus, seed);

sig.timeplot(x, y, seed, 'tWin', 1, 'mode', [0 0 1])
seed.post(0); % Initialize seed with value

for i = 1:10
  if i == 5
    seed.post(0)
  end
  x.post(1)
end

%% Growing an array with scan
% You can grow arrays with scan by using the vertcat or horzcat functions.
% The accumulated/seed value is always the first argument to the function,
% however, you can of course assign them to temporary variables beforehand
% as below.

x = net.origin('x');
f = @(acc,itm) [itm acc]; % Prepend char to array
y = x.scan(f, '!');
h = y.output();
for i = 1:10
  x.post('>')
end

% Below, each time the Signal 'correct' takes a new, truthy value, the
% Signal 'trialSide' updates and scan will call the function horzcat with
% the values of hist and trialSide like so: horzcat(hist, trialSide), which
% is syntactically equivalent to [hist trialSide]
hist = trialSide.at(correct).scan(@horzcat);

%% Introducing extra parameters
% Some functions require any number of extra inputs.  A function can be
% called with these extra parameters by defining them after the 'pars' name
% argument.  All arguments after the input 'pars' are treated as extra
% parameters to map to the function when either the input or seed Signals
% update. 
x = net.origin('x');
seed = net.origin('seed');
seed.post('!'); % Initialize seed with value
f = @(acc,itm,p1) [itm p1 acc]; % Prepend char to array
y = x.scan(f, seed, 'pars', '.'); % Pars may be signals or no
h = y.output();

x.post('>')

%% Parameters may be Signals
% Below we use the scan function to build a character array with strjoin...

x = net.origin('x');
seed = net.origin('seed');
seed.post('0'); % Initialize seed with value
f = @(acc,itm,delim) strjoin({acc, itm}, delim); % Prepend char to array
% f = @(acc,itm) strjoin({acc, itm}, ' + '); 
y = x.scan(f, seed, 'pars', ' + '); % Pars may be signals or any other data type
h = y.output();

x.post('1')
x.post('12')
x.post('18')
x.post('5')
x.post('8')

%% When pars take new values, accumulator function is not called!
% Unlike most other Signals, parameters Signals can take new values
% without causing the function to be called.  Below we define a Signal, p,
% into which we can post the delimiter for the function strjoin.
x = net.origin('x');
seed = net.origin('seed');
p = net.origin('delimiter');
seed.post('0'); % Initialize seed with value
p.post(' + '); % Initialize seed with value
f = @(acc,itm,delim) strjoin({acc, itm}, delim); % Prepend char to array
y = x.scan(f, seed, 'pars', p); % Pars may be signals or any other data type
h = y.output();

x.post('1')
x.post('12')
p.post(' - '); % Updating p doesn't affect scan
x.post('18')
x.post('5')
p.post(' * ');
x.post('8')

%% Scan can call any number of functions at the same time
% Scan can call any number of functions each time one of the input
% Signals updates.  Only the functions whose named inputs update will be
% called.  Remember that all functions called by scan have the accumulated
% value as their first input argument, followed by the input Signal and any
% parameters following the 'pars' input.
x = net.origin('x');
y = net.origin('y');
z = net.origin('z');
seed = net.origin('seed');
seed.post(0); % Initialize seed with value
f1 = @plus; %
f2 = @minus; %
f3 = @times; %
v = scan(x, f1, y, f2, z, f3, seed); % Pars may be signals or any other data type
h = v.output();

x.post(1) % 1
x.post(1) % 2
x.post(1) % 3

y.post(1) % 2
y.post(1) % 1

z.post(2) % 2
z.post(2) % 4
z.post(2) % 8

%% Timing in signals
% Most experiments require things to occur at specific times.  This can be
% achieved by keeping a timing signal that has a clock value posted to it
% periodically.  In the following example, we will create a 'time' signal
% that takes the value returned by 'now' every second.  We achieve this
% with a fixed-rate timer.  In the context of a Signals Experiment, the
% time signal has a time in seconds from the experiment star,t posted every
% iteration of a while loop.

net = sig.Net; % Create a new signals network
clc % Clear previous output for clarity
time = net.origin('t'); % Create a time signal
% NB: The onValue method is very similar to the output method, but allows
% you to define any callback function to be called each time the signal
% takes a value (so long as the handle is still around).  Here we are using
% it to display the formatted value of our 't' signal.  Again, the output
% and onValue methods are not suitable for use within an experiment as the
% handle is deleted.
handle = time.onValue(@(t)fprintf('%.3f sec\n', t*10e4)); %#ok<*NASGU>

t0 = now; % Record current time
% Create a timer that posts the time since t0 to the 'time' signal, at a
% given rate given by 'frequency'.
frequency = 1; % Update the timer every second
tmr = timer('TimerFcn', @(~,~)post(time, now-t0),...
    'ExecutionMode', 'fixedrate', 'Period', 1/frequency);
start(tmr) % Start the timer
disp('Timer started')
% ...Because of the output method, we are seeing the value of the time
% signal displayed every second
pause(3)

%%% Now let's increase the frequency to 10 ms...
stop(tmr) % Stop the timer
frequency = 1e-2; % Frequency now 10x higher
disp('Let''s increase the timer frequency to 10 times per second...')
set(tmr, 'Period', frequency)
pause(1) % Ready... steady... go!
start(tmr)
pause(3) % ...

%%% When we clear the handle, the value is no longer displayed
disp('Clearing the output TidyHandle')
clear handle
pause(1) % ...The values of the 'time' Signal are no longer displayed

%%% Due to the timer, the value of 'time' continues to update
fprintf('%.3f sec\n', time.Node.CurrValue*10e4)
pause(1)% ...
fprintf('%.3f sec\n', time.Node.CurrValue*10e4)
pause(1)

%%% When the timer is stopped, the value of 'time' is no longer updated
disp('Stopping timer');
stop(tmr)
pause(1)% ...
fprintf('%.3f sec\n', time.Node.CurrValue*10e4)
pause(1)% ...
fprintf('%.3f sec\n', time.Node.CurrValue*10e4)
pause(1)% ...
% Let's clear the variables
%delete(tmr); clear tmr frequency t0 time

%% Filtering
% Signals become very useful when you want to define a relationship
% between two events in time.  In addition to viewing Signals as values
% that change over time, they can also be treated as a series of discrete
% values or events used to gate and trigger other Signals.
net = sig.Net;
time = net.origin('t'); % Create a time signal
t0 = GetSecs; % Record current time
frequency = 0.5;
tmr = timer('TimerFcn', @(~,~)post(time, GetSecs-t0),...
    'ExecutionMode', 'fixedrate', 'Period', 1/frequency);

gate = floor(time/5);

ax = sig.timeplot(time, gate, skipRepeats(gate), gate.map(true), ...
  'tWin', 20, 'mode', [0 0 0 1]);
% set(ax, 'ylim', [0 30])
start(tmr) % Start the timer

%%
theta = sin(time);
sig.timeplot(time, theta, theta.keepWhen(theta > 0), 'mode', [0 2 2], 'tWin', 20);

%%
x = -1 + delta(time);
y = 2*x.^2 - x.^3;
y.Name = 'y'; % todo: Change the name of this Signal to something more readable
arm = skipRepeats(y < 1);
trig = arm.setTrigger(y > 1);
% Reset timer
% time = time - GetSecs;
sig.timeplot(x, arm, y, trig, 'tWin', 60); %'mode', [0 2 3 2],

%%
a = mod(floor(time),3) == 0;
b = a.lag(1);
c = a.to(b);
sig.timeplot(time, a, b, c);
% while strcmp(tmr.Running, 'on')
% at, then, setTrigger, skipRepeats, keepWhen

%%
x = net.origin('x'); % Create an origin signal
a = 5; b = 2; c = 8; % Some constants to use in our equation
y = a*x^2 + b*x + c; % Define a quadratic relationship between x and y

sig.timeplot(x,y,y.delta,'mode',[0 2 0],'tWin',6);

for i = -50:2:50
  pause(0.01)
  x.post(i)
end

%% Timing 2 - Scheduling
% The net object contains an attribute called Schedule which stores a
% structure of node ids and their due time.  Each time the schedule is run
% using the method runSchedule, the nodes whose  TODO

net = sig.Net; % Create network
frequency = 10e-2; 
tmr = timer('TimerFcn', @(~,~)net.runSchedule,...
    'ExecutionMode', 'fixedrate', 'Period', frequency);
start(tmr) % Run schedule every 10 ms
s = net.origin('input'); % Input signal
delayedSig = s.delay(5); % New signal delayed by 5 sec
h = output(delayedSig); % Let's output its value
h(2) = delayedSig.onValue(@(~)toc); tic
delayedPost(s, pi, 5) % Post to input signal also delayed by 5 sec
disp('Delayed post of pi to input signal (5 seconds)')
% After creating a delayed post, an entry was added to the schedule
disp('Contents of Schedule: '); disp(net.Schedule) 
fprintf('Node id %s corresponds to ''%s'' signal\n\n', num2str(s.Node.Id), s.Node.Name)
% ...
disp('... 5 seconds later...'); pause(5.1)
% ...
% ... a second entry was added to the schedule, this time for 'delayedSig'.
% This was added to the schedule as soon as the value of pi was posted to
% our 'input' signal.
disp('Contents of Schedule: '); disp(net.Schedule) 
fprintf('Node id %s corresponds to ''%s'' signal\n\n',...
    num2str(net.Schedule.nodeid), delayedSig.Node.Name)
% ...
disp('... another 5 seconds later...'); pause(5.1)
% ...
% 3.14
stop(tmr); delete(tmr); clear tmr s frequency h delayedSig

%% TODO SetEpochTrigger

%% FIXME Move subscriptables here

%% Helpful methods
% delta, lag, buffer, bufferUpTo

%% Demonstration of sig.Signal/log() method
% Sometimes you want the values of a signal to be logged and timestamped.
% The log method returns a signal that carries a structure with the fields
% 'time' and 'value'.  Log takes two inputs: the signal to be logged and
% an optional clock function to use for the timestamps.  The default clock
% function is GetSecs, a PsychToolbox MEX function that returns the most
% reliable system time available.

net = sig.Net; % Create our network
simpleSignal = net.origin('simpleSignal'); % Create a simple signal to log
loggingSignal = simpleSignal.log(@now); % Log that signal using MATLAB's now function
loggingSignal.onValue(@(a)disp(toStr(a))); % Each time our loggingSignal takes a new value, let's display it

simpleSignal.post(3)
pause(1); fprintf('\n\n')

simpleSignal.post(8)
pause(1); fprintf('\n\n')

simpleSignal.post(false)
pause(1); fprintf('\n\n')

simpleSignal.post('foo')

%% Logging signals in a registry
% In order to simplify things, one can create a registry which will hold
% the logs of all signals added to it.  When the experiment is over, the
% registry can return all the logged values in the timestampes optionally
% offset to another clock.  This can be useful for returning values in
% seconds since the start of the experiment
net = sig.Net; % Create our network
t0 = now; % Let's use this as our example reference time
events = sig.Registry(@now); % Create our registy
simpleSignal = net.origin('simpleSignal'); % Create a simple signal to log
events.signalA = simpleSignal^2; % Log a new signal that takes the second power of the input signal
events.signalB = simpleSignal.lag(2); % Log another signal that takes the last but one value of the input signal
simpleSignal.post(3) % Post some values to the input signal
simpleSignal.post(3)
simpleSignal.post(8)

s = logs(events, t0); % Return our logged signals as a structure
disp(s)


%% Demonstration of working values
% Working values of signals are important for proper signal propagation in
% the C code, as you suspected. Basically each time a new signal value is
% posted (i.e. starting from an 'origin' signal), any dependent signals
% need to be updated to take account of the change. This kind of updating
% is implemented by propagating the changes through the nodes -- where each
% signal is a node, and connections between them are direct dependencies.
% Where the interactions between dependent signals get complicated, this
% can mean a signal/node's value can potentially change more than once
% during a full propagation, but will eventually settle to its final
% correct value. Thus we maintain this 'working value' during the process,
% until the propagation is complete. Then all those signals who got a new
% (working) value, will have their current value updated to the new working
% value.

net = sig.Net; % Create our network
origin = net.origin('input');
a = origin.lag(3);
b = a*origin^2;
%   a = src + 1
%   b = a + src
%   b = identity(b) %

% addlistener(b.Node, 'WorkingValue', 'PostSet', @(src,~)disp(src.WorkingValue))

origin.post(1) % Post some values to the input signal
origin.post(2)
origin.post(3)


%% Demonstration of subscriptable signals
% If you have a signal that holds a value that is either an object or a
% struct, you can make that value subscriptable with the method below:
net = sig.Net;
s = struct('A', now, 'B', rand);
x = net.origin('struct');

% The below would not work:
x.post(s); A = x.A; % No appropriate method, property, or field 'A' for class 'sig.node.OriginSignal'.
% Deriving a subscriptable Signal allows us to subscript:
x_sub = x.subscriptable(); % TODO Add note about subsref
a = x_sub.A;
h = output(a);
% We must repost our structure as there are new Signals which won't have
% had the value propergated to them:
x.post(s); 

% Note that with subscriptable Signals the returned value is a new Signal,
% whose value will be updated each time any field is updated in the
% source Signal.  You can subscript such a Signal even if the field doesn't
% exist:
c = x_sub.C;
h = output(c);
x.post(s);
% Note that c never updates as the underlying value in x has no field 'C'. 

%% You can not post to subscriptable Signals, nor assign values to them
% Even if the Signal is derived from an origin Signal:
x_sub.post(s); % Returns a Signal for the subscript of a 'post' field.
post(x_sub, s); % Undefined function 'post' for input arguments of type 'sig.node.SubscriptableSignal'.
% Instead, we use another class of Signal called a Subscriptable Origin
% Signal.  With these Signals we do not post structures, instead one can
% assign individual values to each subscript, which may themselves be
% Signals or otherwise.

x_sub = net.subscriptableOrigin('x');
a = x_sub.A; b = x_sub.B; %c = scan(x_sub.A, @plus, []);
h = [output(a), output(b)] %, output(c)];
x_sub.A = 5;
x_sub.B = x;
x_sub.A = 10;
% TODO Add timeplot
% To repeat, using the post method on any subscripatble Signal, origin or
% otherwise will not have the desired effect.  Instead, simply assign your
% values directly to a subscripatble origin Signal.

% Note again that all Signals update each time any of the subscriptable origin
% Signal's subscripts update.  Thus if we assign a new value to x_sub.B,
% x_sub.A will update but with the same value it had before.

% If you wish to return a plain structure each time a subscriptable Signal
% updates, use the flattenStruct method:
flat = x_sub.flattenStruct();
h = output(flat);
x_sub.A = 10;
x_sub.B = pi;
x_sub.C = true;

% Cache subscripts caches subscripts (not subassigns)

%%
% net = sig.Net;
% A = net.origin('A');
% B = net.origin('B');
% C = net.origin('C');
% structSig = net.origin('structSig');
% post(structSig, struct(...
%   'A', A.scan(@(a,b)nansum([a b]), nan), ...
%   'B', C.scan(@(a,b)nansum([a b]), nan), ...
%   'C', B.scan(@(a,b)nansum([a b]), nan)));
% structSig = structSig.subscriptable;
% post(A, 5)
% sigA = structSig.A;
% h = sigA.output();
% 
% % The below is equivilent
% structSig = net.subscriptableOrigin('structSig');
% structSig.CacheSubscripts = true;
% post(structSig, struct(...
%   'A', A.scan(@(a,b)nansum([a b]), nan), ...
%   'B', C.scan(@(a,b)nansum([a b]), nan), ...
%   'C', B.scan(@(a,b)nansum([a b]), nan)));
% post(A, 5)
% sigA = structSig.A
% 
% %% 
% net = sig.Net;
% structSig = net.subscriptableOrigin('structSig');
% structSig.CacheSubscripts = true; % Essential
% structSig.C = net.origin('C');
% structSig.C; % Essential
% structSig.C = 5;
% structSig.C.Node.CurrValue

%% Running an experiment in Signals
% Let's look at Signals in the context of an experiment.  Signals is a
% module of Rigbox, a toolbox that allows the experimentor to parameterize,
% monitor and log experiments, as well as providing a layer for harware
% configuration.
% 
% Rigbox contains a number of classes that define some sort of experimental
% structure, within which an individual experiment will run.  These are
% found in the +exp package.  For a Signals Experiment this is
% exp.SignalsExp.  SignalsExp imposes the inputs, outputs, timing and trial
% structure, as well as managing the logging and saving of data.  In
% setting up a Signals Experiment, the class is given a structure of
% parameters and a structure of objects that interface with hardware
% (audio, PsychToolbox, a DAQ, etc.).  One of the parameters, 'expDef' is a
% path to a Signals Experiment definition; a function that contains the
% specific 'wire diagram' for that experiment.  An experiment definition
% should have the following inputs: 
%
% t - the timing signal, every iteration of the main experiment loop the
% Signals Experiment posts the number of seconds elapsed
%
% events - a Registry of events to be logged.  All Signals assigned to this
% structure in your experiment definition are turned into logging Signals
% and saved to a file at the end of the experiment.
% 
% parameters - any Signals referenced from this subscriptable Signal are
% considered session specific paramters that the experiment will assign
% values to before every session.  Default values for these paramters may
% be provided within the experiment definition.  Before each session the
% experimentor may choose which paramters have fixed values, and which may
% take a different value each trial.  More on this later.
% 
% vs - all visual elements defined in the experiment definition are
% assigned to this structure to be rendered to the screen.  More on this
% later.
%
% inputs - a Registry of input Signals.  In a Signals Experiment this is
% currently a rotary encoder (wheel) and the keyboard.
%
% outputs - the outputs defined in a hardware structure.
%
% audio - any Signals assigned to this Registry have their values outputted
% to the referenced audio device.  This may also be referenced with a named
% audio device, returning a structure of paramters about the devices such
% as number of output channels and sample rate.
%
% This experiment definition function called just once before entering the
% main experiment loop, where values are then posted to the time and input
% Signals, at which point the values are propergated through the network.

%% Signals Experiment task structure
% Below is the task structure set up before calling the experiment
% definition.
% 
% obj.Time = net.origin('t');
% obj.Events.expStart = net.origin('expStart');
% obj.Events.newTrial = net.origin('newTrial');
% obj.Events.expStop = net.origin('expStop');
% advanceTrial = net.origin('advanceTrial');
% obj.Events.trialNum = obj.Events.newTrial.scan(@plus, 0); % track trial number
% globalPars = net.origin('globalPars');
% allCondPars = net.origin('condPars');
% nConds = allCondPars.map(@numel);
% nextCondNum = advanceTrial.scan(@plus, 0); % this counter can go over nConds
% hasNext = nextCondNum <= nConds;
% % this counter cant go past nConds
% % todo: current hack using identity to delay advanceTrial relative to hasNext
% repeatLastTrial = advanceTrial.identity().keepWhen(hasNext);
% condIdx = repeatLastTrial.scan(@plus, 0);
% condIdx = condIdx.keepWhen(condIdx > 0);
% condIdx.Name = 'condIdx';
% repeatNum = repeatLastTrial.scan(@sig.scan.lastTrue, 0) + 1;
% repeatNum.Name = 'repeatNum';
% condPar = allCondPars(condIdx);
% pars = globalPars.merge(condPar).scan(@mergeStruct, struct).subscriptable();
% pars.Name = 'pars';
% [obj.Params, hasNext, obj.Events.repeatNum] = exp.trialConditions(...
%   globalPars, allCondPars, advanceTrial);
% lastTrialOver = ~hasNext.then(true);
% obj.Listeners = [
%   obj.Events.expStart.map(true).into(advanceTrial) %expStart signals advance
%   obj.Events.endTrial.into(advanceTrial) %endTrial signals advance
%   advanceTrial.map(true).keepWhen(hasNext).into(obj.Events.newTrial) %newTrial if more
%   lastTrialOver.into(obj.Events.expStop) %newTrial if more
%   onValue(obj.Events.expStop, @(~)quit(obj));];

% TODO: mention that endTrial must be defined

%% Visual stimuli
[t, setgraphic] = sig.playgroundPTB;
grating = vis.grating(t);    % we want a gabor grating patch
grating.phase = 2*pi*t*3; % with it's phase cycling at 3Hz
grating.show = true;

elements = StructRef;
elements.grating = grating;

setgraphic(elements);

%% Notes
% 1. Signals objects that are entirely out of scope are cleaned up by
% MATLAB and the underlying C code.  That is, if a Signal is created,
% assigned to a variable, and that variable is cleared then the underlying
% node is deleted if there exist no dependent Signals:
net = sig.Net;
x = net.origin('orphan');
networkInfo(net.Id) % Net with 1/4000 active nodes
clear x
networkInfo(net.Id) % Net with 0/4000 active nodes

% If the Signal is used by another node that is still in scope, then it
% will not be cleaned up:
x = net.origin('x');
y = x + 2; % y depends of two nodes: 'x' and '2' (a root node)
networkInfo(net.Id) % Net with 3/4000 active nodes
clear x % After clearing the handle 'x', the node is still in the network
networkInfo(net.Id) % Net with 3/4000 active nodes
% The node still exists because another handle to it is stored in the
% Inputs property of the node 'y':
str = sprintf('Inputs to y: %s', strjoin(mapToCell(@(n)n.Name, [y.Node.DisplayInputs]), ', '));
disp(str)
disp(['y.Node.DisplayInputs(1) is a ' class(y.Node.DisplayInputs(1))])

% 2. Rule exceptions: merge and scan pars