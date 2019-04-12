classdef SignalsExpTest < handle
%% Description
  %SIGNALSEXPTEST Contains *Signals* information for running a *Signals* Exp Def from EXPTEST
  %
  % See also: EXPTEST, EXP.SIGNALSEXP
  
%% properties

  % can be set in command line to improve visualization
  properties
    ScreenH % handle to PTB Screen which displays visual stimuli
  end
  
%% properties (SetAccess = ?exp.ExpTest)

  % set by 'exp.ExpTest'
  properties (SetAccess = ?exp.ExpTest)
    ETest % 'ExpTest' object - parent for this class (see constructor method) 
  end
  
%% properties (SetAccess = private)

  properties (SetAccess = private)  
    Clock = hw.ptb.Clock % 'Clock' object that returns current time (in s)
    QuitKey = KbName('q') % Keyboard key for quitting experiment and closing 'ScreenH'
    Net % 'sig.Net' object - signals network
    T % 'sig.Node.OriginSignal' object - signals 'time' origin signal
    Events % 'sig.Registry' object - signals 'events' ExpDef input arg
    Params % 'sig.SubscriptableSignal' object - signals 'params' ExpDef input arg
    VisStim % 'sig.StructRef' object - signals 'visStim' ExpDef input arg
    Inputs % 'sig.Registry' object - signals 'inputs' ExpDef input arg
    Outputs % 'sig.Registry' object - signals 'outputs' ExpDef input arg
    Audio % 'audstream.Registry' object - signals 'audio' ExpDef input arg
    ParamsLog % 'sig.SubscriptableSignal' object - log of parameters' time & value updates during experiment
    Occ % handle to 'vis.init' shader - occulus visual stimuli viewing model
    TexturesByID = containers.Map('KeyType', 'char', 'ValueType', 'uint32') %'containers.Map' object - keys: texture ID strings; values: openGL ID
    LayersByName = containers.Map %'containers.Map' object - visual element fields
    Data % 'struct' containing all the data from the experiment
    Listeners % array of 'TidyHandle' listeners for signal updates
    IsLooping = false % flag for if experiment is running
    StimWindowInvalid = false % flag for flipping PTB Screen (which must occur after VisStim changes)
    CursorAsWheel = true % flag for having mouse cursor emulate steering wheel
    CursorAsWheelKey = KbName('c') % keyboard key to set/unset 'CursorAsWheel'
    CursorDelta = 0 % change in cursor position after disabling/enabling 'CurosorAsWheel'
    CursorGain = 0.33 % gain factor for having cursor pixel X-location post into wheel
    AsyncFlipping = false % flag for whether 'ScreenH' is currently asynchronously flipping
    SignalUpdates = struct('name', cell(500,1), 'value', cell(500,1),... 
      'timestamp', cell(500,1))
    NumSignalUpdates = 0
    GlobalPars % global parameters in GUI
    CondPars % conditional parameters in GUI   
  end
  
%% methods (Exposed)
  methods % can be called via 'exp.ExpTest', or Test Panel GUI, or command line (for instantiation, deletion, or visualization)
    
    function obj = SignalsExpTest(parent)
    % 'parent' is the 'ExpTest' object which instantiates this
    % 'SignalsExpTest' object
    
      obj.ETest = parent;
      clock = obj.Clock;
      clockFun = clock.now;
      obj.Inputs = sig.Registry(clockFun);
      obj.Outputs = sig.Registry(clockFun);
      obj.VisStim = StructRef;
      obj.Audio = audstream.Registry();
      obj.Events = sig.Registry(clockFun);
      obj.Net = sig.Net;
      obj.T = obj.Net.origin('t');
      obj.Events.expStart = obj.Net.origin('expStart');
      obj.Events.newTrial = obj.Net.origin('newTrial');
      obj.Events.expStop = obj.Net.origin('expStop');
      obj.Inputs.wheel = obj.Net.origin('wheel');
      obj.Inputs.wheelMM = obj.Inputs.wheel.skipRepeats();
      obj.Inputs.wheelDeg = obj.Inputs.wheel.skipRepeats();
      obj.Inputs.cursor = obj.Net.origin('cursor');
      obj.Inputs.keyboard = obj.Net.origin('keyboard');
      [~, globalStruct, condStruct] = ...
        obj.ETest.Parameters.toConditionServer;
      advanceTrial = obj.Net.origin('advanceTrial');
      obj.GlobalPars = obj.Net.origin('globalPars');
      obj.CondPars = obj.Net.origin('condPars');
      [obj.Params, hasNext, obj.Events.repeatNum] = exp.trialConditions(...
        obj.GlobalPars, obj.CondPars, advanceTrial);
      obj.Events.trialNum = obj.Events.newTrial.scan(@plus, 0); % track trial number
      lastTrialOver = then(~hasNext, true);
      expDefFun = fileFunction(obj.ETest.Parameters.Struct.defFunction);
      obj.Data.expDef = obj.ETest.Parameters.Struct.defFunction;
      expDefFun(obj.T, obj.Events, obj.Params, obj.VisStim, obj.Inputs,...
        obj.Outputs, obj.Audio)
      % set listeners which will proceed experiment after 'expStart' is
      % posted to in 'run'
      obj.Listeners = [
        obj.Events.expStart.map(true).into(advanceTrial) % expStart signals advance
        obj.Events.endTrial.into(advanceTrial) % endTrial signals advance
        advanceTrial.map(true).keepWhen(hasNext).into(obj.Events.newTrial) % newTrial if more
        lastTrialOver.into(obj.Events.expStop) % newTrial if more
        obj.Events.expStop.onValue(@(~) obj.quit);
        obj.Inputs.cursor.into(obj.Inputs.wheel)
        ];
      
      % add listeners to appropriately update strings for 'Trial Number'
      % and 'Reward Delivered' on 'ExpTestPanel'
      setCtrlStr = @(h)@(v)set(h, 'String', toStr(v));
      obj.Listeners = [obj.Listeners
        obj.Events.trialNum.onValue(setCtrlStr(obj.ETest.TrialNumCount));
        ];
      if isfield(obj.Outputs, 'reward')
        obj.Listeners = [obj.Listeners
        obj.Outputs.reward.scan(@plus, 0).onValue(...
          setCtrlStr(obj.ETest.RewardCount))
        ];
      end
      
      obj.ParamsLog = obj.Params.log();
      obj.GlobalPars.post(globalStruct);
      obj.CondPars.post(condStruct);
      
      % create a listener for user changing parameters in test panel GUI
      addlistener(obj.ETest.ParamEditor,... 
        'Changed', @(src,event) obj.userChangedParam);
      
      % get access to PTB Screen and set viewing model (to emulate the 3
      % screens in Burgess Steering Wheel Task)
      obj.ScreenH = obj.ETest.ScreenH;
      obj.Occ = vis.init(obj.ScreenH);
      
      if obj.ETest.ScreenView % if this flag has been set to view PTB window as single-screen
        center = [0 0 0];
        viewingAngle = 0;
        dimsCM = [20 20];
        pxBounds = [0 0 400 400];
        screen = vis.screen(center, viewingAngle, dimsCM, pxBounds);
      else
        screenDimsCm = [20 25]; %[width_cm height_cm of real experiment screen]
        pxW = 960/3; % 3 screens % 1280
        pxH = 400; % 600
        screen(1) = vis.screen([0 0 9.5], -90, screenDimsCm, [0 0 pxW pxH]); % left screen
        screen(2) = vis.screen([0 0 10],  0 ,...
          screenDimsCm, [pxW 0 2*pxW pxH]); % ahead screen
        screen(3) = vis.screen([0 0 9.5],  90,...
          screenDimsCm, [2*pxW  0 3*pxW pxH]); % right screen
      end
      
      obj.Occ.screens = screen;
    end
    
    function run(obj)
    % the major method of this class. runs the experiment. 
    % directly or indirectly calls all other methods besides the constructor method
    
      obj.init;
      Screen('Flip', obj.ScreenH);
      obj.createLivePlot;
      obj.mainLoop;
      obj.cleanup;
      obj.saveData;
    end
    
    function userChangedParam(obj, ~, ~)
    % callback for when user updates a parameter in the GUI:
    % updates parameter to new value
    
      [~, newGlobalParStruct, newCondParStruct] = ...
        obj.ETest.ParamEditor.Parameters.toConditionServer;
      obj.GlobalPars.post(newGlobalParStruct);
      obj.CondPars.post(newCondParStruct);
    end
    
    function quit(obj)
    % stops the experiment when the user clicks the GUI 'Stop' button
    % or when 'expStop' in an exp def evaluates to true
    
      tmrs = timerfind;
      if ~isempty(tmrs)
        stop(tmrs)
        delete(tmrs)
      end
      
      obj.Data.endStatus = 1;
      obj.IsLooping = false;
      obj.ETest.IsRunning = false;
      obj.ETest.StartButton.set('String', 'Start');
    end
    
  end
  
%% methods (private)

  methods (Access = private)
    
    function init(obj)
      % Performs initialisation before running
      
      % create and initialise a key press queue for responding to input
      KbQueueCreate();
      KbQueueStart();
      
      % MATLAB time stamp for starting the experiment
      obj.Data.startDateTime = now;
      obj.Data.startDateTimeStr = datestr(obj.Data.startDateTime);
      
      %init end status to nothing
      obj.Data.endStatus = [];
      
      % load each visual stimulus
      cellfun(@obj.loadVisual, fieldnames(obj.VisStim));
      % each event signal should send signal updates
      queuefun = @(n,s)s.onValue(fun.partial(@queueSignalUpdate, obj, n));
      evtlist = mapToCell(@(n,v)queuefun(['events.' n],v),...
        fieldnames(obj.Events), struct2cell(obj.Events));
      outlist = mapToCell(@(n,v)queuefun(['outputs.' n],v),...
        fieldnames(obj.Outputs), struct2cell(obj.Outputs));
      inlist = mapToCell(@(n,v)queuefun(['inputs.' n],v),...
        fieldnames(obj.Inputs), struct2cell(obj.Inputs));
      parslist = queuefun('pars', obj.Params);
      obj.Listeners = vertcat(obj.Listeners, ...
        evtlist(:), outlist(:), inlist(:), parslist(:));
    end
    
    function loadVisual(obj, name)
    % loads the visual stimulus
    
      layersSig = obj.VisStim.(name).Node.CurrValue.layers;
      obj.Listeners = [obj.Listeners
        layersSig.onValue(fun.partial(@obj.newLayerValues, name))];
      obj.newLayerValues(name, layersSig.Node.CurrValue);
    end
    
    function newLayerValues(obj, name, val)
    % creates new layers for the visual stimulus
      if isKey(obj.LayersByName, name)
        prev = obj.LayersByName(name);
        prevshow = any([prev.show]);
      else
        prevshow = false;
      end
      obj.LayersByName(name) = val;
      
      if any([val.show]) || prevshow
        obj.StimWindowInvalid = true;
      end
    end
    
    function createLivePlot(obj)
    % creates the 'LivePlot' figure, if user-specified via GUI
    
      if obj.ETest.LivePlot
        obj.ETest.LivePlotFig = figure('Name', 'LivePlot',...
          'NumberTitle', 'off', 'Color', 'w',...
          'DeleteFcn', @(~,~) emptyHandle(obj));
        sig.timeplot(obj.T, obj.Events,...
          'Parent', obj.ETest.LivePlotFig, 'xlabelOff', 1);
      end
      
      function emptyHandle(obj)
      % callback for deleting the 'LivePlot' figure: 
      % clears the figure handle in the 'ExpTest' object
      
        obj.ETest.LivePlotFig = [];
      end
    end
    
    function queueSignalUpdate(obj, name, value)
    % queues signals to be updated during experiment
    
      timestamp = clock;
      nupdates = obj.NumSignalUpdates;
      if nupdates == length(obj.SignalUpdates)
        %grow message queue by doubling in size
        obj.SignalUpdates(2*end+1).value = [];
      end
      idx = nupdates + 1;
      obj.SignalUpdates(idx).name = name;
      obj.SignalUpdates(idx).value = value;
      obj.SignalUpdates(idx).timestamp = timestamp;
      obj.NumSignalUpdates = idx;
    end
    
    function mainLoop(obj)
    % runs 'while' loop that updates *signals* reactive network during experiment
    
      obj.IsLooping = true;
      obj.T.post(obj.Clock.now);
      obj.Events.expStart.post(obj.ETest.Parameters.Struct.expRef);
      
      while obj.IsLooping
        obj.checkInput;
        
        % signaling:
        if obj.CursorAsWheel
          obj.Inputs.cursor.post((obj.CursorGain * GetMouse()) +... 
            obj.CursorDelta);
        end
        obj.T.post(obj.Clock.now);
        obj.Net.runSchedule;
        
        % redraw stimulus window:
        if obj.StimWindowInvalid
          obj.ensureScrnReady;
          obj.drawFrame;
          Screen('AsyncFlipBegin', obj.ScreenH);
          obj.AsyncFlipping = true;
          obj.StimWindowInvalid = false;
        end
        drawnow; % execute any other callbacks
      end
      obj.ensureScrnReady;
    end
    
    function checkInput(obj)
    % Checks for and handles inputs during experiment
    
      [pressed, keysPressed] = KbQueueCheck();
      if pressed
        if any(keysPressed(obj.QuitKey))
            obj.ETest.startStopExp;
        elseif any(keysPressed(obj.CursorAsWheelKey))
          if ~obj.CursorAsWheel % if we're re-enabling CursorAsWheel
            obj.CursorDelta = obj.CursorDelta -... 
              (obj.CursorGain * GetMouse());
            fprintf('Mouse Cursor as Wheel Emulator has been re-set\n');
            obj.CursorAsWheel = ~obj.CursorAsWheel;
          else % we're disabling CursorAsWheel
            obj.CursorAsWheel = ~obj.CursorAsWheel;
            obj.CursorDelta = obj.Inputs.cursor.Node.CurrValue;
            fprintf('Mouse Cursor as Wheel Emulator has been unset\n');
          end
        end
      end
    end
    
    function ensureScrnReady(obj)
    % ends PTB screen flipping to ensure proper next display of visual stimulus
    
      if obj.AsyncFlipping
        Screen('AsyncFlipEnd', obj.ScreenH);
      end
    end
    
    function drawFrame(obj)
    % draws the visual stimulus on the PTB screen
    
      layerValues = cell2mat(obj.LayersByName.values());
      Screen('BeginOpenGL', obj.ScreenH);
      vis.draw(obj.ScreenH, obj.Occ, layerValues, obj.TexturesByID);
      Screen('EndOpenGL', obj.ScreenH);
    end
    
    function cleanup(obj)
    % cleans-up this object appropriately when the experiment has ended
      
      obj.Data.endDateTime = now;
      obj.Data.endDateTimeStr = datestr(obj.Data.endDateTime);
      obj.Data.duration = etime(...
        datevec(obj.Data.endDateTime), datevec(obj.Data.startDateTime));
      obj.Data.events = logs(obj.Events); % can't call 'logs' method with dot notation (due to 'subsref' of sig.Registry < util.StructRef)
      obj.Data.paramValues = obj.ParamsLog.Node.CurrValue.value;
      obj.Data.paramsTimes = obj.ParamsLog.Node.CurrValue.time;
      obj.Data.inputs = logs(obj.Inputs);
      obj.Data.outputs = logs(obj.Outputs);
      
      Screen('Flip', obj.ScreenH);
      obj.Listeners = [];
      obj.deleteGlTextures;
      obj.Net.delete;
      KbQueueStop();
      KbQueueRelease();
    end
    
    function deleteGlTextures(obj)
    % deletes the openGL textures when the experiment has ended
    
      tex = cell2mat(obj.TexturesByID.values);
      fprintf('Deleting %i textures\n', numel(tex));
      Screen('AsyncFlipEnd', obj.ScreenH);
      Screen('BeginOpenGL', obj.ScreenH);
      obj.TexturesByID.remove(obj.TexturesByID.keys);
      obj.LayersByName.remove(obj.LayersByName.keys);
      glDeleteTextures(numel(tex), tex);
      Screen('EndOpenGL', obj.ScreenH);
    end
    
    function saveData(obj)
    % saves an experiment block file, if user-specified via GUI
    
      if obj.ETest.SaveBlock
        g = groot;
        scrnSz = g.ScreenSize(3:4); % get screensize for setting position of following dialog boxes
        dirpath = 0; % path for saving block file
        while ~dirpath % make sure user selects a valid path for saving
          dirpath = uigetdir(pwd,... 
            'Select Folder for Saving "Block" Data File'); % set 'dirpath' using 'uigetdir'
          
          if dirpath == 0 % if user cancels
            cancelSaveDH = dialog('Position', [scrnSz(1)/2, 100, 250 175],...
              'Name', 'Cancel Save?', 'WindowStyle', 'normal');
            dGrid = uix.Grid('Parent', cancelSaveDH, 'Padding', 10);
            uix.Empty('Parent', dGrid);
            yesCancelBtn = uicontrol('Style', 'pushbutton', 'Parent', dGrid,...
              'String', 'Don''t save block file',...
              'Callback', @(src,~) cancelSave(src));
            uix.Empty('Parent', dGrid); uix.Empty('Parent', dGrid);
            noCancelBtn = uicontrol('Style', 'pushbutton', 'Parent', dGrid,...
              'String', 'Save block file', 'Callback',...  
              @(src,~) cancelSave(src));
            uix.Empty('Parent', dGrid);
            dGrid.set('Heights', [-3 -2 -3]);
            uiwait(cancelSaveDH);
          end
          
          if dirpath == -1 % if user confirms they're canceling save
            return;
          end
        end
        
        obj.getBlockFileName(dirpath);
      end
      
      function cancelSave(src,~)
      % callback function within 'saveData':
      % cancels the save if user decides to via GUI
      
        if strcmpi(src.String(1), 'd'), dirpath = -1; end % if 'yesCancelBtn' pushed
        % if src is yesCancelBtn, dirpath = -1, end
        delete(cancelSaveDH);
      end
      
    end
    
    function getBlockFileName(obj, dirpath)
      % gets file name for 'saveData' for saving the block file
      
      g = groot;
      scrnSz = g.ScreenSize(3:4); % get screensize for setting position of following dialog boxes
      expRef = obj.ETest.Parameters.Struct.expRef; % get expRef
      blockpath = strcat(dirpath, '\', expRef, '_Block.mat');
      filenameDH = dialog('Position', [scrnSz(1)/2, 100, 300 250],... 
      'Name', 'Enter File Name', 'WindowStyle', 'normal');
      dBox = uix.VBox('Parent', filenameDH, 'Padding', 10);
      uix.Empty('Parent', dBox); uix.Empty('Parent', dBox);
      txt = uicontrol('Style', 'text', 'Parent', dBox,... 
        'String', 'Enter Block File Name for Saving Experiment Data:',... 
        'FontSize', 11);
      usrTxt = uicontrol('Style', 'edit', 'Parent', dBox,... 
        'String', blockpath);
      uix.Empty('Parent', dBox); uix.Empty('Parent', dBox);
      uicontrol('Style', 'pushbutton', 'Parent', dBox, 'String', 'Confirm',...
        'Callback', @(~,~) confirmSave);
      dBox.set('Heights', [-1 -1 -4 -2 -1 -1 -2])
      
      % helper callback function for 'getBlockFileName' - checks whether
      % filename already exists in path
      function confirmSave(~,~)
        finalpath = usrTxt.String;
        if exist(finalpath, 'file') % if filename already exists in path
          overwriteDH = dialog('Position', [scrnSz(1)/2, 100, 300 200],...
              'Name', 'Overwrite Filename?', 'WindowStyle', 'normal');
            dGrid = uix.Grid('Parent', overwriteDH, 'Padding', 10);
            uix.Empty('Parent', dGrid);
            yesOverwrite = uicontrol('Style', 'pushbutton', 'Parent', dGrid,...
              'String', 'Yes, overwrite existing file',...
              'Callback', @(src,~) overwrite(src));
            uix.Empty('Parent', dGrid); uix.Empty('Parent', dGrid);
            noOverwrite = uicontrol('Style', 'pushbutton', 'Parent', dGrid,...
              'String', 'No, re-name file',...
              'Callback',  @(src,~) overwrite(src));
            uix.Empty('Parent', dGrid);
            dGrid.set('Heights', [-3 -2 -3]);
            uiwait(filenameDH);
        else
          superSave(finalpath, struct('block', obj.Data));
          delete(filenameDH);
        end
        
        function overwrite(src,~)
        % helper callback function for 'confirmSave':
        % if specified filename already exists, then user chooses to 
        % overwrite, or to rename the file to be saved
          
          if strcmpi(src.String(1), 'y') % if 'yesOverwrite' button pushed
            delete(overwriteDH); delete(filenameDH);
            superSave(finalpath, struct('block', obj.Data));
          else
            delete(overwriteDH); delete(filenameDH);
            obj.getBlockFileName(dirpath)
          end
        end
        
      end
      
    end
    
  end
  
  
end