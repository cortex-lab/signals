## Description:

This `docs` folder contains files that are useful for learning how to use *Signals*.  Experiment definition (exp def) functions are run within the Rigbox Experiment framework and require [Rigbox](https://github.com/cortex-lab/Rigbox).  These functions can be run by calling `eui.SignalsTest`.  The files in this folder are not on the paths, so cd into the folder before running.


## Contents:

### Tutorials folder

Contains files that are useful for learning how to use *Signals*:

- 'GettingStartedWithSignals': Those new to *Signals* should start here. This script contains information on how *Signals* works, and how to create signals in a *Signals* network using common MATLAB and *Signals* specific methods.

- 'signalsExpDefTutorial': This file is a tutorial for creating a *Signals* Experiment definition.  This tutorial walks through setting up and running different versions of a *Signals* Experiment based on the [Burgess Steering Wheel Task](https://www.biorxiv.org/content/biorxiv/early/2017/07/25/051912.full.pdf). To run, call `eui.SignalsTest(@signalsExpDefTutorial)`.

- 'SignalsPrimer': An in-depth walkthrough of *Signals*.

### Examples folder

Contains example exp defs and standalone experiment scripts:

- 'advancedChoiceWorld': This exp def runs a 2 Alternate Unforced Choice version of the Burgess Steering Wheel Task.  To run, call `eui.SignalsTest(@advancedChoiceWorld)`.

- 'imageWorld': This demonstrates a passive image presentation experiment.  The original image dataset is not included.  To run, call `eui.SignalsTest(@imageWorld)`.

- 'mouseTheremin': This function maps the current horizontal cursor position to a given
frequency, and as the mouse is moved the frequency changes much like a
theremin. To run, call `mouseTheremin`.

- 'ringach98': This script launches an orientation detection/discrimination task based on a [task created by Dario Ringach](https://www.sciencedirect.com/science/article/pii/S0042698997003222?via%3Dihub).  To run, call `mouseTheremin`.

- 'signalsPong': This exp def runs the classic computer game, Pong.  To run, call `eui.SignalsTest(@signalsPong)`.