function axh = timeplot(varargin)
%SIG.TIMEPLOT Plots signals over time
% Creates a subplot for each signal input and plots its values as it
% updates. If a StructRef or Registry is provided, each field is plotted 
% as an individual signal. Each signal's "Name" field is used as its 
% identification; however, if it is empty, the variable name is used
% instead.
%
% Clicking on each subplot will cycle through the three plot modes. The
% default mode (0) creates a stair plot with each value update marked with
% an "x". Mode 1 plots each value as a discrete point. Mode 2 plots a
% simple line, with "now" markers to indicate value updates. Note, if a
% signal takes a vector or matrix as its value, the mode is switched to 1
% and the size of the array is added as a text annotation. If the value
% is a character array, the mode is switched to 1 and the value is plotted
% as a text annotation.
%
% Inputs:
%   One or more Signals or StructRef (including subclass) objects.
%
% Optional name-value pairs:
%   'parent' - Figure handle for creating plots. If none is
%     provided, a new figure is created.
%   'tWin' - Length of time window to plot in seconds (default 5)
%   'mode' - Plotting mode, either 0, 1 or 2. May be a single value to set
%   all plots, or an array the length of input Signals.  
%
% Outputs:
%   'axh' - A list of axes handles, one for each subplot.
%
% Example:
%   axh = sig.timeplot(x, y, z, t);
%   axh = sig.timeplot(t, events, 'mode', 1, 'tWin', 60);
%   axh = sig.timeplot(t, x, 'parent', f, 'mode', [0 1]);
%
% See also SIG.PLOT
% 
% TODO Vararg for axes name value args, e.g. LineWidth
% TODO Deal with logging signals & registries & subscriptable signals
% TODO Deal with strings, arrays, structures, cell arrays

%% Process inputs

% set defaults for potential name-value paired input args
argsStruct.figh = ...
  figure('Name', 'LivePlot', 'NumberTitle', 'off', 'Color', 'w');
argsStruct.tWin = 5;
argsStruct.mode = 0;
firstName = find(cellfun(@ischar, varargin), 1); % look for name-value paired args
if ~isempty(firstName) % if there are name-value pairs
  pairedArgs = reshape(varargin(firstName:end),2,[]); % get paired args
  % if the name-value pairs don't match up, throw error
  if ~all(cellfun(@ischar, (pairedArgs(1,:)))) ||...
      ~all(cellfun(@isnumeric, (pairedArgs(2,:)))) ||...
      mod(length(varargin(firstName:end)),2)
    error('Error matching name-value paired input args');
  end
  
  % for the specified input args, change default input args to new values
  for pair = pairedArgs
    argName = pair{1};
    if any(strcmpi(argName, fieldnames(argsStruct)))
      argsStruct.(argName) = pair{2};
    end
  end
end
mode = argsStruct.mode;
tWin = argsStruct.tWin;
figh = argsStruct.figh;

varargin = varargin(1:firstName-1); % get only the signal input args
% Clear the figure
clf(figh);

%% Prep signals to plot

% Initialize cell array to store all signals and their names
signals = cell(length(varargin),1);
names = cell(length(varargin),1);
for i = 1:length(varargin)
  s = varargin{i};
  % Get the name of the signal. If Name is empty, use the variable name
  name = iff(isempty(s.Name), inputname(i), s.Name);
  switch class(s)
    case {'sig.Registry', 'StructRef'}
      % For StructRef objects and their subclasses, exract their Signals
      % and set the names to be the fieldnames of the Signal
      names{i} = strcat([name '.'], fieldnames(s));
      signals{i} = struct2cell(s);
    case {'sig.Signal', 'sig.node.Signal', ...
        'sig.node.ScanningSignal', 'sig.node.OriginSignal'}
      % For normal Signals, simply store them and their name
      names{i} = name;
      signals{i} = s;
    case {'sig.node.SubscriptableOriginSignal', ...
        'sig.node.SubscriptableSignal'}
      % TODO
    otherwise
      error('Unrecognized type')
  end
end

% Flatten cell arrays as there maybe nested cells if a StructRef was
% provided
signals = cellflat(signals);
names = cellflat(names);

n = numel(names); % Number of Signals
x_t = cell(n,1); % Initialize a cell array of update times
tstart = []; % Initialize start time
lastval = cell(n,1); % Initialize array to store the previous 1 value

% Change colour map so that there is the largest possible colour difference
% between signals as a visual aid
cmap = colormap(figh, 'hsv');
skipsInCmap = floor(length(cmap) / n);
cmap = cmap(1:skipsInCmap:end, :);

% Set some default values
args = {'linewidth' 2};
fontsz = 7;

% Initialize an empty array of Axes handle
axh = matlab.graphics.axis.Axes.empty(n,0);

% If one mode value was provided, repmat the value for all subplots
if numel(mode) == 1
  mode = repmat(mode, n, 1);
end

%% Create signal subplots

for i = 1:n
  % For each Signal, create a subplot
  axh(i) = subtightplot(n,1,i,[0.02,0.2],0.05,0.05,'parent',figh);
  % Derive a new Signal that stores the value and its update time in a
  % struct
  x_t{i} = signals{i}.map(...
    @(x)struct('x',{x},'t',{GetSecs}), '%s(t)');
  % Set the title of the subplot to be the Signal's name
  title(axh(i), names{i}, 'interpreter', 'none');
end
% Set the default font size and set the axes to add new plots without
% clearing the old
set(axh,'NextPlot','add', 'fontsize', fontsz);
xlabel(axh(end), 't (s)', 'fontsize', fontsz); % set xlabel for final subplot
% Initialize an array of listener handles for the Signal updates
listeners = TidyHandle.empty(n,0);
for i = 1:n % add listeners for the Signals that will update the plots
  listeners(i) = onValue(x_t{i}, @(v)new(i,v));
end
% Set a callback so that clicking each subplot will iterate the plotting
% mode
set(axh,'ButtonDownFcn',@(s,~)cycleMode(s))
% Remove listeners upon close.  NB: creating a function handle that
% contains the listeners keeps them around until the figure is closed.  If
% the figure is cleared or reset, however, the listeners will not be
% deleted.
set(figh, 'DeleteFcn', @(~,~)delete(listeners));

  function new(idx, value)
    % NEW The callback function for plotting Signals values
    
    % If tstart is empty, initialize to now
    if isempty(tstart)
      tstart = GetSecs;
    end
    if ischar(value.x)
      % If the value is a charecter array, store the string and overwrite
      % to be a bool indicating whether the array is empty
      str = value.x;
      value.x = iff(isempty(value.x),0,1);
      % Set the mode to be 1 - a series of discrete values
      mode(idx) = 1;
      % Add the string to the plot as a text annotation
      text(axh(idx), value.t-tstart, value.x+0.1, str,...
        'HorizontalAlignment', 'center',...
        'VerticalAlignment', 'bottom', ...
        'Interpreter', 'none');
      % Adjust the y limits to allow space for the text
      ylim(axh(idx), [0 1.5])
    elseif numel(value.x) > 1
      % If the value is numrical array, store the size of the array as a
      % string and overwrite the value to be the number of elements in the
      % array
      str = num2str(size(value.x));
      % The y axis is now the size of the array
      ylabel(axh(idx),'size')
      value.x = numel(value.x);
      % Set the mode to be 1 - a series of discrete values
      mode(idx) = 1;
      % Add the size of the array as a text annotation
      text(axh(idx), value.t-tstart, value.x+0.1, str,...
        'HorizontalAlignment', 'center',...
        'VerticalAlignment', 'bottom', ...
        'Interpreter', 'none');
    end
    % If there is no previous value, just use the current value
    if isempty(lastval{idx})
      lastval{idx} = value;
    end
    
    switch mode(idx)
      case 0 % plot as a signal, but with change points shown
        xx = [lastval{idx}.x value.x];
        tt = [lastval{idx}.t value.t]-tstart;
        scatter(axh(idx), value.t-tstart, value.x, 'x', 'MarkerEdgeColor', cmap(idx,:), args{:});
        stairs(axh(idx), tt, xx, 'Color', cmap(idx,:), args{:});
      case 1 % plot as a stream of discrete events, no intevening values
        xx = [0 value.x];
        tt = [value.t value.t]-tstart;
        scatter(axh(idx), value.t-tstart, value.x, 'o', 'MarkerEdgeColor', cmap(idx,:), args{:});
        stairs(axh(idx), tt, xx, 'Color', cmap(idx,:), args{:});
      case 2 % plot as a signal, without showing change points, and interpolate
        xx = [lastval{idx}.x value.x];
        tt = [lastval{idx}.t value.t]-tstart;
        line(tt, xx, 'Parent', axh(idx), 'Color', cmap(idx,:), args{:});
    end
    % Set the last value to be the current value
    lastval{idx} = value;
    % Set the x limits to be the length of the current time window
    set(axh, 'Xlim', [GetSecs-tstart-tWin GetSecs-tstart+0.1]);
  end

  function cycleMode(src)
    % CYCLEMODE Callback for changing the mode of the plot
    id = src==axh; % Get the axes handle of the subplot that was clicked
    if mode(id) == 2
      mode(id) = 0; % If the mode was at 2, cycle back round to 0
    else % Otherwise iterate
      mode(id) = mode(id) + 1;
    end
  end
end

