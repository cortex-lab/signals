## Description:

This `docs` folder contains files that are useful for learning how to use *Signals*. This folder contains `tutorials` and `examples` folders, and the `examples` folder contains `scripts` and `exp defs` folders. The `scripts` folder contains *Signals* examples that can be run by just calling the filename within MATLAB (e.g. `ringach98`). The `exp defs` folder contains *Signals* experiment definition functions that are run in [Rigbox's](https://github.com/cortex-lab/Rigbox) Experiment framework. These exp defs can be run in Rigbox's SignalsTest GUI, which can be launched by calling `eui.SignalsTest`.

All files in this folder should not be added directly to MATLAB's path, so we recommend, within MATLAB, to change into the folder containing the file you wish to run before running.


## Contents:

### `tutorials` folder

Contains files that are useful for learning about and how to use *Signals*:

- `SignalsPrimer.m` - Those new to *Signals* should start here. This script contains information on how *Signals* works, and how to create signals in a *Signals* network using common MATLAB and *Signals* specific methods.

- `SignalsPrimer2.m` - A follow-up to `SignalsPrimer` which contains more advanced information, such as...

- `signalsExpDefTutorial.m` - A tutorial for creating a *Signals* experiment definition.  This tutorial walks through setting up and running different versions of a *Signals* Experiment based on the [Burgess Steering Wheel Task](https://www.biorxiv.org/content/biorxiv/early/2017/07/25/051912.full.pdf). To run, call `eui.SignalsTest(@signalsExpDefTutorial)`.

- `using_visual_stimuli.m` - A guide for learning how *Signals* interacts with Psychtoolbox and OpenGL to create visual stimuli.

### `examples/scripts` folder

Contains example standalone *Signals* experiments that can be run as scripts.

- `mouseTheremin` - Maps the current horizontal cursor position to a given
frequency, and as the mouse is moved the frequency changes much like a
theremin. To run, call `mouseTheremin`.

- `ringach98` - Launches an orientation detection/discrimination task based on a [task created by Dario Ringach](https://www.sciencedirect.com/science/article/pii/S0042698997003222?via%3Dihub). To run, call `ringach98`.

- `screenImage` - Produces Gabor grating image data based on specified parameters. To run, call `screenImage`.

### `examples/exp defs` folder

Contains example exp defs that can be run via Rigbox's SignalsTestGUI(`eui.SignalsTest`).

- `advancedChoiceWorld.m` - A 2 Alternate Unforced Choice version of the Burgess Steering Wheel Task. To run, call `eui.SignalsTest(@advancedChoiceWorld)`.

- `advancedChoiceWorldExpPanel.m` - An ExpPanel class to accompany `advancedChoiceWorld`. *Note: this is not an exp def, it is called automatically when the `advancedChoiceWorld` exp def is run to create psychometric plots that display realtime performance.

- `choiceWorld.m` - A 2 Alternate Unforced Choice version of the Burgess Steering Wheel Task.  To run, call `eui.SignalsTest(@choiceWorld)`.

- `choiceWorldExpPanel.m` - An ExpPanel class to accompany `choiceWorld`. *Note: this is not an exp def, it is called automatically when the `choiceWorld` exp def is run to create psychometric plots that display realtime performance.

- `imageWorld` - A demonstration of a passive image presentation experiment. The original image dataset is not included. To run, call `eui.SignalsTest(@imageWorld)`.

- `signalsPong` - This exp def runs the classic computer game, Pong. To run, call `eui.SignalsTest(@signalsPong)`.