## Description:

This 'docs' folder contains files that are useful for learning how to use *Signals*. 

## Contents:

### Tutorials folder

Contains files that are useful for learning how to use *Signals*:

- GettingStartedWithSignals* - Those new to *Signals* should start here. This script contains information on how *Signals* works, and how to create signals in a *Signals* network using common MATLAB and *Signals* specific methods.

- signalsExpDefTutorial* - This file is a tutorial for creating a *Signals* Experiment Definition (aka an 'Exp Def'). An Exp Def is a MATLAB function that is executed when running a *Signals* Experiment within Rigbox. This tutorial walks through setting up and running different versions of a *Signals* Experiment based on the [Burgess Steering Wheel Task](https://www.biorxiv.org/content/biorxiv/early/2017/07/25/051912.full.pdf).

- SignalsPrimer - This script contains additional information on *Signals'* mechanics. It also contains examples of *Signals-y* things which may not have been covered in the above files, and which an experimenter may be able to incorporate into their Experiment Definitions.

*May be run from the ExpTestPanel, which can be launched by running `exp.ExpTest`. See the documentation within `exp.ExpTest` for futher info.

### Examples folder

Contains example exp defs and standalone experiment scripts:

- advancedChoiceWorld* - This exp def runs a 2 Alternate Unforced Choice version of the Burgess Steering Wheel Task.

- advancedChoiceWorldExpPanel* - An example custom experiment panel for mc.

- mouseTheremin - This function maps the current horizontal cursor position to a given frequency, and as the mouse is moved the frequency changes much like a theremin. 

- ringach98 - This script launches an orientation detection/discrimination task based on a [task created by Dario Ringach](https://www.sciencedirect.com/science/article/pii/S0042698997003222?via%3Dihub) 

- signalsPong - This exp def runs the classic computer game, Pong.

*Requires Rigbox.
