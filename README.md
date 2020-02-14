# *signals*
![Custom badge](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fsilent-zebra-36.tunnel.datahub.at%2Fcoverage%2Fsignals%2Fmaster)
![Custom badge](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fsilent-zebra-36.tunnel.datahub.at%2Fstatus%2Fsignals%2Fmaster)

Wouldn't it be nice if you could describe the presentation of stimuli in your experiment with simple, concise code? i.e.

* Something like making a grating drift should be as straightforward as its mathematical description: `grating.phase = 2*pi*t*temporalFreq`.
* It should be free from the messy details of how it actually gets presented: no unpredictable loops, tangles of event-handlers, tricky state management nor low-level graphics rendering.
* ...and yet, still benefit from easy data-logging, parameterisation and remote control.

This is the goal of *signals*. Principally, *signals* allows for monitoring and 
manipulating stimuli (and other experimental parameters) over time. This is done by representing each parameter of interest as a signal!

## Hello, grating!

Here's how you could define a 3Hz drifting grating patch to be presented for half a second (with intervening 1 second blank periods), using *signals*:

```matlab
function driftingGrating(t, events, pars, visStim)
grating = vis.grating(t);    % we want a Gabor grating patch
grating.phase = 2*pi*t*3; % with it's phase cycling at 3Hz

stimOff = events.newTrial.delay(0.5); % stimOff occurs 0.5s after new trial starts
events.endTrial = stimOff.delay(1);  % next trial should start 1s after stimOff
grating.show = events.newTrial.to(stimOff);  % stimulus visible between trial onset & stimOff

visStim.grating = grating; % add the stimulus to experiment
end
```

Now let's present our grating 15 times:

```matlab
log = exp.runTrials(@driftingGrating, 15);
```

Note that we didn't specify a position for the grating, nor its spatial frequency, so it will always appear using some defaults (e.g. as defined in `vis.gabor()`; positioned directly ahead with 1 cyc/&deg;). In fact, we would probably like all our stimulus attributes parameterised so they can be varied, by experiment, by trial, by whatever:

```matlab
function driftingGrating2(t, events, pars, visStim)
grating = vis.grating(t);    % we want a gabor grating patch
grating.azimuth = pars.azimuth;
grating.altitude = pars.altitude;
grating.spatialFreq = pars.spatialFreq;
grating.phase = 2*pi*t*pars.temporalFreq; % now it's cycling at whatever pars.temporalFreq is

stimOff = events.newTrial.delay(pars.stimDuration); % parameterise stimulus duration
events.endTrial = stimOff.delay(pars.isi);  % parameterise period between stimuli
grating.show = events.newTrial.to(stimOff);  % stimulus visible between trial onset & stimOff

visStim.grating = grating;
end
```

Now, we're going to need some values for those parameters before we can actually run an experiment. One way is to pass in a MATLAB `struct` with fields corresponding to each named parameter. But, a simple GUI for configuring them first would be nice:

```matlab
paramValues = exp.promptForParams(@driftingGrating2);
log = exp.runTrials(@flashedGrating2, paramValues);
```

The `exp.promptForParams` function actually calls your presentation definition just to infer what parameters it requires. It will then show a (blocking) GUI requesting those parameters, and return your final choices in an appropriate `struct`. Finally, we use them to run the experiment presentation, now fully parameterised.

## Working with signals

The *signals* framework is built around the paradigm of functional reactive programming, which can simplify problems that primarily involve dealing with change over time. A signal is an object that represents a value that changes over time. Furthermore, you can apply transformations to signals to derive a new signal whose values are obtained by applying an operation to the values of its input signals.

You can use most of the standard MATLAB operations on signals, with intuitive results, e.g.

```matlab
% if x and y are signals,
z = x + y;    % z is a new signal that updates with x and y as their sum
c = 2*cos(y); % c will always be twice the cosine of y
posx = x > 0; % posx updates with x, true if x > 0, false otherwise
```
In each case, these expressions return a new signal whose value will update as any of the source signals change.

Note: these operations actually use the signal [mapping functions](#mapping-signals). E.g. `sig1 + sig2` is shorthand for `sig1.plus(sig2)` (or equivalently `plus(sig1, sig2)`), which ultimately evaluates to `sig1.map2(@plus, sig2)`. Thus, here the `plus` function is being called on each signal's value.

### Some Examples of Signal Transformations

`signal.delay(period)` returns a new signal that is a time delayed version of `signal`. I.e. each time `signal`'s value changes, the resultant signal's value will change to the same value, but `period` seconds later. `period` can be a constant or a time-varying signal.

`signal.at(sampler)` returns a new signal that takes the current value from `signal` each time `sampler` takes a new true value.

`what.keepWhen(pred)` returns a signal that takes each new value from `what` whenever `pred` is true. i.e. `pred` acts as a gate to filter values from what.

`from.to(otherSignal)` returns a signal that will go true when `from` goes true, then false when `otherSignal` goes true.

`cond(pred1, value1, pred2, value2, ...)` returns a signal that takes the value from the first `valueX` (with X in 1...N) signal whose corresponding predicate `predX` is true.

### Mapping signals

`signal.map(f)` returns a new signal whose values result from mapping values in `signal` using the function `f`.

`inp1.map(inp2, ..., f)` returns a new signal where its values result from mapping values from a set of input signals `inpX` (with X in 1...N)  using the function `f`. Note that the resultant signal updates if any of the source signal change.

`signal.scan(f, seed)` returns a new signal where its values result from iteratively scanning each new value in `signal` through function `f` together with the last resulting value. i.e. this allows you to create a signal which iteratively updates based on the current value and each new piece of information. `seed` defines the intial value of the result signal.

## Code organization

Below is a list of *signal*'s subdirectories and an overview of their respective contents.

### +audstream

The "audio stream" package contains code for creating and using new audio streams in experiments with audio stimulus presentation, and interacting with PsychPortAudio devices (via PsychToolbox).

### +expr

The "math expressions" package contains code for allowing the use of math expressions whose syntax is not supported by default in MATLAB on signals.
(E.g. c = a(b:c))

### +fun

The "functions" package contains functions that act on other functions to do things like restrict the scope of, return partial applications of, and map functions. 

### +sig

The "signal" package contains code for creating signals, nodes, and the network that contains them, defining how signals can interact, plotting signals, and generally keeping track of signals over time.

### +ui

The "user interface" package contains code for the creation and display of GUIs used in *signals*.

### +vis 

The "visual stimulus" package contains code for creating various visual stimuli to be used when running *signals*.

### java

The "java" subdirectory contains java code that mostly pertains to creating and using visual renderings.

### mexnet, mexnet-vs

The "mex network" subdirectories contain code with mex compilations of underlying C source code (mexnet) and the C source code itself (mexnet-vs) that allows for improved performance when operations are performed on signals during run-time.

### util

The "utilities" subdirectory contains assorted helper functions, mex files, and classes which provide auxiliary services to the rest of *signals*, and don't schematically fit into any of the other packages or subdirectories.

## Running Experiments

*Signals* is used as a submodule within [Rigbox](https://github.com/cortex-lab/Rigbox). Best practice is to clone the Rigbox repository and use the *Signals* submodule within Rigbox, rather than using this repository as a standalone. For more information on running *Signals* experiments in Rigbox, see the Rigbox repository. For more information on using *Signals*, see [docs](https://github.com/cortex-lab/signals/tree/dev/docs).
