function [t, setgraphic] = playgroundPTB(parent)
% SIG.TEST.PLAYGROUNDPTB Creates a stimulus window for playing with Signals
%   Opens a PsychToolbox window and returns a timing signal.  Visual Signal
%   elements can be loaded by calling the setgraphic function. Pressing the
%   play button starts a timer that redraws the window and posts values to
%   the timing signal.  If no input is provided a new figure is created
%   with a button for starting/stopping the update timer.
%
%   Input:
%     parent (optional): The parent container for the play/pause button.
%
%   Outputs:
%     t (sig.Signal): A Signal for time elapsed since update timer started.
%     setgraphic (function_handle): Function for loading Visual Signal
%                                   elements.
%
%   Example:
%     % Create a drifting Gabor patch
%     [t, setgraphic] = playgroundPTB();
%     vs = StructRef;
%     gabor = vis.grating(t); % we want a gabor grating patch
%     gabor.phase = 2*pi*t*3; % with its phase cycling at 3Hz
%     gabor.show = true;
%     vs.gabor = grating;
%     setgraphic(vs); % draw textures
%
% See also EXP.TEST, EXP.SIGNALS

% Initialize OpenGL for rendering Signals visual elements
global AGL GL GLU %#ok<NUSED>
InitializeMatlabOpenGL

% Process input
% If no parent figure is given, create one
if nargin < 1
  parent = figure(...
    'Name', 'Signals playground', ...
    'NumberTitle', 'off',...
    'Toolbar', 'none', ...
    'Menubar', 'none');
end

% Set callback to clean up everything when parent figure is destroyed
set(ancestor(parent, 'figure'), 'DeleteFcn', @cleanup);
% Create timer for updating our time signal and the stimulus window
tmr = timer(...
  'Name', 'MainLoop', ...
  'ExecutionMode', 'fixedSpacing', ...
  'Period', 5e-3, ...
  'TimerFcn', @process);

% Get number of available screens
nScreens = Screen('Screens');
screenNum = iff(max(nScreens) > 1, 1, 0);
% Create a new PsychToolbox window with a default size
screenDims = [0,0,1280,600]; % Dimentions in px of PTB window
colour = 255/2; % Make the background middle grey
vc = Screen('OpenWindow', screenNum, colour, screenDims);

% Create a play button for starting and stopping the 'Main loop' timer
vbox = uix.VBox('Parent', parent);
btnbox = uix.HBox('Parent', vbox);
btnh = uicontrol('Parent', btnbox, 'Style', 'pushbutton',...
  'String', 'Play', 'Callback', @(~,~)startstop());

% Create a new Signals network and a time signal
sn = sig.Net; % New network
sn.Debug = 'on'; % Activate debug mode by default
% A new input signal to represent number of seconds between calls to the
% process function
dt = sn.origin('dt');
tlast = []; % Initialize variable for storing time of last process call
t = dt.scan(@plus, 0); % Count up the time in seconds from the start
t.Name = 'time'; % Rename signal for clarity

% Initialize the visual stimulus framework
listhandle = []; % An array of listener handles
renderCount = 0; % Keep track of number of times redraw called (for debugging)
% Create container for storing GL texture handles by the textureId name
textureById = containers.Map('KeyType', 'char', 'ValueType', 'uint32');
% Create container for storing the visual element textures by their user
% given names
layersByName = containers.Map();

% Create occulus viewing model for transforming texture units from visual
% degrees to pixels
model = vis.init(vc);
screenDimsCm = [20 25]; % Simulate physical dimentions [width_cm heigh_cm]
pxW = screenDims(3)/3; % Simulate 3 'virtual' screens
pxH = screenDims(4);
screens(1) = vis.screen([0 0 9.5], -90, screenDimsCm, [0 0 pxW pxH]);        % left screen
screens(2) = vis.screen([0 0 10],  0 , screenDimsCm, [pxW 0 2*pxW pxH]);    % ahead screen
screens(3) = vis.screen([0 0 9.5],  90, screenDimsCm, [2*pxW  0 3*pxW pxH]); % right screen
model.screens = screens; % Apply screen configuration
invalid = false; % Initialize redraw flag
% Return the function handle for rendering Signals visual elements
setgraphic = @setElements;

%%% Helper functions
  function startstop()
    % STARTSTOP Callback to Play/Pause pushbutton
    %   Starts/stops the 'Main loop' timer and changes the button string
    %   accordingly.
    running = strcmp(tmr.Running, 'on');
    if running
      stop(tmr);
      set(btnh, 'String', 'Play');
    else
      tlast = GetSecs;
      start(tmr);
      set(btnh, 'String', 'Pause');
    end
  end

  function process(~,~)
    % PROCESS Update time signal and draw stimuli
    %  This function is similar to the mainloop method of the exp.Signals
    %  Experiment class.  Updates the time signal and if required, redraws
    %  the stimuli.
    %
    % See also EXP.SIGNALS/MAINLOOP
    tnow = GetSecs; % Current time (seconds)
    %     tic
    try % Catch and ignore any errors; we're only playing around
      post(dt, tnow - tlast); % Change since last update
    catch
    end
    %     fprintf('%.0f\n', 1000*toc);
    tlast = tnow; % record last update time
    runSchedule(sn); % Process any scheduled updates (i.e. delay signals)
    if invalid % If visual stimulus has changed since last call...
      layerValues = cell2mat(layersByName.values()); % Get textures
      Screen('BeginOpenGL', vc);
      vis.draw(vc, model, layerValues, textureById); % Render
      Screen('EndOpenGL', vc);
      Screen('Flip', vc, 0); % Flip buffer
      renderCount = renderCount + 1; % Iterate render count
      invalid = false; % Screen is no longer invalid
    end
  end

  function cleanup(~,~)
    % CLEANUP Callback for figure deletion
    %  Stops and deletes the 'Main loop' timer, closes any other associated
    %  plots, deletes the GL textures and Signals network
    %
    % See also EXP.TEST
    stop(tmr);
    delete(tmr);
    try % Close the 'LivePlot' figure if open (see EXP.TEST)
      close('LivePlot')
    catch
    end
    % delete gl textures
    delete(listhandle) % Clear listeners for layer changes
    tex = cell2mat(textureById.values); % Get handles to all GL textures
    fprintf('Deleting %i textures\n', numel(tex));
    Screen('AsyncFlipEnd', vc);
    Screen('BeginOpenGL', vc);
    glDeleteTextures(numel(tex), tex); % Delete GL textures
    textureById.remove(textureById.keys); % Clear texture map
    Screen('EndOpenGL', vc);
    Screen('CloseAll'); % Close PTB window
    sn.delete(); % Delete the network
  end

  function setElements(elems)
    % SETELEMENTS Sets callbacks for drawing visual elements
    %   Adds a grid to the visual elements structure and creates listener
    %   handles for loading the texture layers into the buffer each time
    %   they update.  Calls to this function overwrites any previously
    %   loaded visual elements.
    %
    %   Input:
    %     elems (StructRef) : Structure of Signals visual elements, each a
    %                         Subscriptable Signal with a layers field
    %                         containing a struct array of texture layers.
    %
    % See also EXP.SIGNALS/LOADVISUAL, NEWLAYERVALUES
    rfgrid = vis.grid(t); % Create a grid element
    elems.rfgrid = rfgrid; % Assign to struct
    fields = fieldnames(elems); % Get visual element names
    listhandle = TidyHandle.empty(0, numel(fields)); % Initialize handlelist
    for fi = 1:numel(fields)
      layersSig = elems.(fields{fi}).Node.CurrValue.layers; % Get texture layer signal
      listhandle(fi) = ... % call newLayerValues upon new texture values
        layersSig.onValue(fun.partial(@newLayerValues, fields{fi}));
      newLayerValues(fields{fi}, layersSig.Node.CurrValue); % Draw texture
    end
    %rfgrid.show = true; % Show RF grid
  end

  function newLayerValues(name, layer)
    % NEWLAYERVALUES Callback for layer updates for window invalidation
    %  When a visual element's layers change, store the new values and
    %  check whether stim window needs redrawing.  The following two
    %  conditions invalidate the stim window:
    %    1. Any of the layers have show == true
    %    2. Show has changed from true to false for any layer
    %
    %  Inputs:
    %    name (char) : The name of the stimulus (entry name in
    %      obj.Visual StructRef)
    %    layer (struct) : A struct array of layers with new values
    %
    % See also SETELEMENTS, VIS.DRAW, VIS.EMPTYLAYER, EXP.SIGNALS/NEWLAYERVALUES
    if isKey(layersByName, name)
      % If layer already loaded, check if any show == true previously
      prev = layersByName(name);
      prevshow = any([prev.show]);
    else % Otherwise it clearly wasn't previously shown
      prevshow = false;
    end
    layersByName(name) = layer; % Store new layer(s) value by element name
    % Determine whether new value invalidates stimulus window
    if any([layer.show]) || prevshow
      invalid = true;
    end
  end
end

