function axh = plot(varargin)
%SIG.TEST.PLOT Plot values of two signals against each other
%   SIG.TEST.PLOT([AX, ]X, Y) Plots signal x vs signal y in ax and returns
%   the plot axes handle.
%
%   Inputs: ax (optional) - handle to plot axes
%           x - Signal to be plotted on the x axis
%           y - Signal to be plotted on the y axis
%           Name-Value pairs - optional name-value pairs for the axes
%
%   Outputs: axh - Axes handle used.  If the first input was an axes
%                  handle, the same handle is returned
%
%   See also SIG.TIMEPLOT
% TODO Deal with empty input names

% If the first input argument is a handle, assume an Axes handle was
% provided
if ishandle(varargin{1})
  axh = varargin{1};
  cla(axh); % clear axes
  % Assume the next two arguments are the Signals to be plotted on the x-
  % and y-axes respectively
  x = varargin{2};
  y = varargin{3};
  varargin(1:3) = []; % clear from args list
  % Set the title to be the name of the two input arguments
  titleStr = [inputname(2) ' vs ' inputname(3)];
else
  % If no handle was provided, create a new figure
  figure('Name', 'X-Y Plot', 'NumberTitle', 'off', 'Color', 'w');
  % Set the title to be the name of the two input arguments
  titleStr = [inputname(1) ' vs ' inputname(2)];
  axh = subplot(1,1,1);
  % Assume the next two arguments are the Signals to be plotted on the x-
  % and y-axes respectively
  x = varargin{1};
  y = varargin{2};
  varargin(1:2) = []; % clear from args list
end
title(axh, titleStr);
% Set the axes labels
xlabel(axh, x.Name); ylabel(axh, y.Name);
% If no LineWidth name-value pair in inputs, set a default of 2
if ~any(strcmp(varargin, 'LineWidth'))
  varargin = [varargin {'LineWidth', 2}];
end

% Derive new Signals that hold a vector of the previous and current values
xx = [x.lag(1) x];
yy = [y.lag(1) y];
% Create a Signal that concatinates these into the matrix:
% [prev_x, x; prev_y, y]
sc = xx.map2(yy, @vertcat);
% Upon updating, update the plot using the 'new' function
h = sc.onValue(@new);

% Remove listeners upon close.  NB: creating a function handle that
% contains the listener h keeps it around until the figure is closed.  If
% the Axes are cleared or reset, however, the listener will not be deleted.
set(axh,'NextPlot','add','DeleteFcn', @(~,~)delete(h));
% set(bui.parentFigure(axh), 'DeleteFcn', @(~,~)delete(h));

  function new(xy)
    % NEW Plot new values
    %  Assumes input is a 2x2 array
    xx = xy(1,:); % first row is [prev_x new_x]
    yy = xy(2,:); % second row is [prev_y new_y]
    plot(axh, xx, yy, varargin{:})
  end

end

