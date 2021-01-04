# Changelog

## [Latest](https://github.com/cortex-lab/signals/commits/master) [1.3.1]

- HOTFIX: Duplicate test name in Signals_test; added test for `then` method

## [1.3.0]

- vis.checker6 is renamed to vis.checker, all others have been removed
- A new filter method was added that filters its input signal's values using a function handle
- A new method overloading num2str
- Huge amount of documentation and unit tests added
- bufferUpTo(0) now never updates
- setEpochTrigger now actually works (fixed subsref error)!
- Fixed some incorrect error IDs
- Fixed incomplete teardowns in tests
- sig.test.create Signal names is now an input parameter
- sig.test.sequence name is now an input parameter, and cell arrays are now supported, allowing for nonhomogeneous sequences
- vis.circLayer dimensions may now be a Signal
- Full refactoring of vis.grid and vis.patch code, now all fields can be a Signal
- Added sample images so that imageWorld can run 'out of the box'
- getOr input arg 'field' may now be a string array
- When a subscriptable Signal's name changes its subscriptable's name will also change
- The name of a scanning signal is now consistant
- The number of samples to buffer can now be a signal; now done via a transfer function
- setEpochTrigger added to method list; Name prop now more readable; Refctored
- Subscriptable Signals now correctly represented in timeplot plots (shows the field names as plot annotations)
- toStr will correctly stringify map.Containers objects
- When Deep flag is true in SubscriptableSignal, multi-level dot syntax subscripting can be achieved;
Removed unused 'Subscriptable' property
- SubscriptableOriginSignal now supports multi-level dot syntax subscripting, e.g. s = structSig.f1.f2.fn
- Added Java source code to java folder

## [1.2.0]<

- HOTFIX: Bugfix for MATLAB versions <2018b `2b7324c`

## [1.1.0]

- Added documentation for visual stimuli `5bf38cb`
- Variable output assignment `ddfcfc`
- Added methods for erf, rot90, flipud, fliplr, min, max `ddfcfc`
- Signals can map to other signals `a1b9eb`
- Tests for methods and utilities `e016f0`, `3621b1`, `1fb3cd`
- Fix for checking functions in path on new MATLAB versions `e3cb05`
- Added help files for mexnet `ba51d1`