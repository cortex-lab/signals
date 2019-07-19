classdef ExpTest < handle
%% Description
%EXPTEST Creates a GUI for testing *Signals* Exp Defs on a personal PC
%
% See also: EXP.SIGNALSEXPTEST, EUI.MCONTROL
%% Usage:
% 1) Run the command 'expTestPanel = exp.ExpTest;' to launch the 
% 'ExpTestPanel' GUI
% 2) (Optional) Use the 'Select Subject...' drop-down menu if you want to
% load a parameter set from a particular subject (see '4)' below), and/or
% save a 'block' .mat file
% 3) Click the 'Select Signals Exp Def' button to choose the *Signals* Exp
% Def to be run
% 4) (Optional) Use the 'Select parameters...' drop-down menu if you want
% to load a specific parameter set
% 5) (Optional) Click the 'Options' button to select which options to
% enable when running the Exp Def. Currently, these are:
%   a) Live-Plotting of signals
%   b) Saving a 'block' file
%   c) Viewing the PTB Window as a single screen (by default it's set as
%   divided into 3 screens, to mimic the Burgess Steering Wheel Task)
% 6) Click the 'Start' button to run the Exp Def. This button will turn
% into a 'Stop' button after the experiment starts running - click it again
% to end the experiment (alternatively, press the 'q' keyboard key to
% stop the experiment). To run another exp def in the same panel (or the
% same exp def that was just run), repeat 'Usage' from step 3).
%
% *Note: While the experiment is running, the position of the mouse
% cursor will be set to emulate the wheel. Press the 'c' keyboard key
% while experiment is running to disable/enable this feature.
%
  
%% properties
  
  % can be set in GUI or command line to improve visualization
  properties
    ScreenH % handle to PTB Screen which displays visual stimuli
    LivePlotFig % handle to figure for live-plotting signals
    LoggingDisplay % window within 'PanelH' for showing log output
  end 
  
%% properties (SetAccess = ?exp.SignalsExpTest)

  % set by 'exp.SignalsExpTest'
  properties (SetAccess = ?exp.SignalsExpTest)
    SigExpTest % 'SignalsExpTest' object which contains info for running the *Signals* experiment
    IsRunning = false % flag for if Exp Def is running
  end 
  
%% properties (SetAccess = private)
  
  properties (SetAccess = private)
    PanelH % 'ExpTestPanel' figure handle
    MainGrid % main 'uix.GridFlex' object; child of 'PanelH'
    ExpGrid % top 'uix.Grid' object; child of 'MainGrid'
    ExpTopBox % 'uix.HBox' object, containing UI elements to run the Exp Def; child of 'ExpGrid'
    ExpBottomBox % 'uix.HBox' object, containing UI elements which display experiment info; child of 'ExpGrid'
    SubjectList % 'bui.Selector' object containing the subject-list
    Subject % string of currently selected subject (optional)
    SelectExpDef % handle to 'Select Signals Exp Def' push-button
    ExpDef % function handle to currently chosen Signals Exp Def
    ExpDefPath % fullfile path of ExpDef
    OptionsButton % handle to 'Options' push-button
    LivePlot = 0 % option for live-plotting signals during experiment
    SaveBlock = 0 % option for saving 'block' file at experiment end
    SingleScreen = 0 % option for viewing PTB window as a single screen
    StartButton % handle to 'Start' push-button
    ParamPanel % 'uix.Panel' object containing the 'ParamGrid'; child of 'MainGrid'
    ParamGrid % 'uix.GridFlex' object containing 'ParamTopBox' and 'ParamBottomBox'; child of 'ParamPanel'
    ParamTopBox % 'uix.HBox' object containing 'bui.Selector' object for list of saved parameter sets; child of 'ParamGrid'
    ParamBottomBox % 'uix.VBox' object containing 'Parameters'; child of 'ParamGrid'
    Parameters = exp.Parameters % 'exp.Parameters' object containing the current parameters
    ParametersList % 'bui.Selector' object containing saved list of parameters sets
    ParametersProfile = '<defaults>' % string of selected parameters set from 'ParametersList'
    ParamEditor % 'eui.ParamEditor' object for viewing/changing the current parameters
    RewardCount % uicontrol text object for reward delivered
    TrialNumCount % uicontrol text object for trial number
    QuitKey = KbName('q') % Keyboard key for quitting experiment and closing 'ScreenH'
  end
  
%% methods

  % can be called via Test Panel GUI, or command line (for instantiation, 
  % deletion, or visualization)
  methods 
    
    function obj = ExpTest(expdef)
      % constructor method runs the 'buildUI' method to create the ExpTest
      % panel
      obj.buildUI;
      if nargin > 0 % if we called 'exp.ExpTest' with an input arg of the exp def file
        assert(ischar(expdef),...
          'exp.ExpTest input arg must be in the form of a string');
        obj.ExpDefPath = which(expdef);
        if isempty(obj.ExpDefPath), obj.delete(); error('"%s" not found.', expdef); end
        obj.ExpDef = fileFunction(obj.ExpDefPath);
        obj.loadParameters(obj.ParametersProfile);
        obj.setPTB;
        obj.SigExpTest = exp.SignalsExpTest(obj); % create fresh 'SignalsExpTest' object
      end
      obj.checkForUpdate;
    end
    
    function paramProfileChanged(obj, src, ~)
    % callback for user GUI-selected parameter profile
      if isa(src, 'eui.ParamEditor') % if a change was made to a single parameter
        return
      end
      profile = cell2mat(src.Option(src.SelectedIdx));
      obj.loadParameters(profile);
    end
    
    function setOptions(obj, ~, ~)
    % callback for 'Options' button: sets options for running the Exp Def: 
    % 1) yes/no for live-plotting; 2) yes/no for saving a block file
    
      g = groot;
      scrnSz = g.ScreenSize(3:4);
      dh = dialog('Position', [scrnSz(1)/2, 100, 300 250], 'Name',...
        'Exp Test Options', 'WindowStyle', 'normal');
      dCheckBox = uix.VBox('Parent', dh, 'Padding', 10);
      livePlotCheck = uicontrol('Parent', dCheckBox, 'Style', 'checkbox',... 
        'String', 'Plot Signals?', 'Value', obj.LivePlot);
      saveBlockCheck = uicontrol('Parent', dCheckBox, 'Style', 'checkbox',... 
        'String', 'Save Block file?', 'Value', obj.SaveBlock);
      SingleScreenCheck = uicontrol('Parent', dCheckBox, 'Style', 'checkbox',... 
        'String', 'View PTB Window as Single Screen?',... 
        'Value', obj.SingleScreen);
      CloseHBox = uix.HBox('Parent', dCheckBox, 'Padding', 10);
      uicontrol('Parent', CloseHBox, 'String', 'Save and Close',... 
        'Callback', @(~,~) helper);
      
      function helper(~,~)
      % callback function for the 'Save and Close' button defined above
      
        obj.LivePlot = livePlotCheck.Value;
        obj.SaveBlock = saveBlockCheck.Value;
        obj.SingleScreen = SingleScreenCheck.Value;
        delete(dh)
      end
  
    end
    
    function startStopExp(obj, ~, ~)
    % callback for 'Start/Stop' button: 
    % stops experiment if running, and starts experiment if not running
      
      if obj.IsRunning %  stop experiment
        obj.log('ExpTestPanel Experiment Ending');
        obj.SigExpTest.quit;
        obj.SigExpTest = [];
        obj.IsRunning = false;
      else % start experiment
        if isempty(obj.SigExpTest)
          error('Select Signals Exp Def Before Starting Experiment.');
        end
        livePlotH = findobj('Type', 'Figure', 'Name', 'LivePlot');
        if ~isempty(livePlotH)
          close('LivePlot')
        end
        obj.log('ExpTestPanel Experiment Starting');
        obj.StartButton.set('String', 'Stop');
        obj.IsRunning = true;
        obj.SigExpTest.run;
      end
      
    end
    
    function log(obj, message)
      % displays experiment output in 'LoggingDisplay'
      timestamp = datestr(now, 'dd-mm-yyyy HH:MM:SS');
      toDisplay = sprintf('[%s] %s', timestamp, message);
      curDisplay = get(obj.LoggingDisplay, 'String');
      set(obj.LoggingDisplay, 'String', [curDisplay; toDisplay]);
    end
    
    function clearLog(obj, src, event)
      % clears 'LoggingDisplay'
      obj.LoggingDisplay.String = {};
    end
    
    function delete(obj, ~, ~)
      % callback for when this object (and 'PanelH') have been deleted:
      % makes sure to delete 'ScreenH' PTB Screen and 'LivePlot' figure
      
      if ~isempty(obj.PanelH)
        delete(obj.PanelH)
      end
      if ~isempty(findobj('Type', 'figure', 'Name', 'LivePlot'))
        delete('LivePlot')
      end
      if isequal(obj.ScreenH, Screen('Windows'))
        Screen('Close', obj.ScreenH)
      end
    end
    
  end
  
%% methods (private)
  
  methods (Access = private)
    
    function buildUI(obj)
    % Create Exp Test Panel figure and all UI elements:
    % Layout arrangement: 'PanelH' -> 'MainGrid' ->
    % (('ExpGrid' -> ExpTopBox, ExpBottomBox), ('ParamPanel' ->
    % ('ParamGrid' -> ParamTopBox, ParamBottomBox)))
    
      g = groot;
      scrnSz = g.ScreenSize(3:4);
      
      % create main figure
      obj.PanelH = figure('Name', 'ExpTestPanel', 'NumberTitle', 'off',...
        'Toolbar', 'None', 'Menubar', 'None', 'Position', [scrnSz(1)/2-350,...
        scrnSz(2)/2-475, 950, 700], 'DeleteFcn', @(src,event) obj.delete);
      
      % GUI layout toolbox functions to set-up ui elements within main figure
      obj.MainGrid = uix.GridFlex('Parent', obj.PanelH, 'Spacing', 10,...
        'Padding', 5);     
      obj.ExpGrid = uix.Grid('Parent', obj.MainGrid, 'Spacing', 5,...
        'Padding', 5);   
      obj.ExpTopBox = uix.HBox('Parent', obj.ExpGrid, 'Spacing', 5,...
        'Padding', 5);
      obj.ExpBottomBox = uix.HBox('Parent', obj.ExpGrid, 'Spacing', 5,...
        'Padding', 5);      
      % get subject list from server via 'dat.listSubjects'
      obj.SubjectList = bui.Selector(obj.ExpTopBox, [{'Select Subject...'};... 
        dat.listSubjects]);
      obj.SubjectList.addlistener('SelectionChanged', @(src,event)...
        obj.selectSubject(src, event));      
      obj.SelectExpDef = uicontrol('Parent', obj.ExpTopBox,... 
        'Style', 'pushbutton', 'String', 'Select Signals Exp Def',... 
        'Callback', @(src,event) obj.getSetExpDef(src,event));     
      obj.OptionsButton = uicontrol('Parent', obj.ExpTopBox,... 
        'Style', 'pushbutton', 'String', 'Options',... 
        'Callback', @(src,event) obj.setOptions(src,event));     
      obj.StartButton = uicontrol('Parent', obj.ExpTopBox,... 
        'Style', 'pushbutton', 'String', 'Start',... 
        'Callback', @(src,event) obj.startStopExp(src,event));     
      uicontrol('Parent', obj.ExpBottomBox, 'Style', 'text', 'String',...
        'Trial Number:');    
      obj.TrialNumCount = uicontrol('Parent', obj.ExpBottomBox,... 
        'Style', 'text', 'String', '0');    
      uicontrol('Parent', obj.ExpBottomBox, 'Style', 'text',... 
        'String', 'Reward Delivered:');    
      obj.RewardCount = uicontrol('Parent', obj.ExpBottomBox,... 
        'Style', 'text', 'String', '0');
      obj.ExpGrid.set('Heights', [-3 -2]);      
      obj.ParamPanel = uix.Panel('Parent', obj.MainGrid,... 
        'Title', 'Parameters', 'Padding', 5);     
      obj.ParamGrid = uix.GridFlex('Parent', obj.ParamPanel, 'Spacing', 5,...
        'Padding', 5);    
      obj.ParamTopBox = uix.HBox('Parent', obj.ParamGrid, 'Spacing', 5,...
        'Padding', 5);     
      obj.ParamBottomBox = uix.VBox('Parent', obj.ParamGrid, 'Spacing', 5,...
        'Padding', 5);     
      obj.LoggingDisplay = uicontrol('Parent', obj.MainGrid,... 
        'Style', 'listbox', 'Enable', 'inactive', 'String', {},... 
        'Tag', 'Logging Display');
      c = uicontextmenu(obj.PanelH);
      obj.LoggingDisplay.UIContextMenu = c;
      m1 = uimenu(c, 'Label', 'Clear Logging Display',...
        'callback', @(src,event) obj.clearLog(src,event));
      obj.MainGrid.set('Heights', [-2 -9 -3]);
    end
    
    function selectSubject(obj, src, ~)
      % callback for obj.SubjectList (when a subject is selected)
      
      if ~strcmp(src.Selected, 'Select Subject...')
        obj.Subject = src.Selected;
      else
        obj.Subject = [];
      end
    end
    
    function getSetExpDef(obj, ~, ~)
      % gets and sets *signals* Exp Def
      
      if ~isempty(findobj('Type', 'figure', 'Name', 'LivePlot'))
        close('LivePlot')
      end
      obj.TrialNumCount.String = '0'; obj.RewardCount.String = '0';
      [mfile, mpath] = uigetfile('*.m', 'Select Exp Def');
      if ~mfile, return; end
      obj.ExpDef = fileFunction(mpath, mfile);
      obj.ExpDefPath = fullfile(mpath, mfile);
      obj.loadParameters(obj.ParametersProfile);
      obj.setPTB;
      obj.SigExpTest = exp.SignalsExpTest(obj); % create fresh 'SignalsExpTest' object
    end
    
    function loadParameters(obj, profile)
    % loads parameters for one of three cases: 
    % 1) the chosen Exp Def, 2) the last set for a chosen subject (if a 
    % subject was selected), or 3) a saved parameter set on the server
    % 
    % Inputs:
    %   'profile': the parameters' profile (i.e. a parameter set) 
    
      if isempty(obj.ParametersList) % initialize parameters list
        % concatenate standard parameter sets to server saved parameter sets
        sets = [{'<defaults>', '<last for subject>'}';... 
          fieldnames(dat.loadParamProfiles('custom'))];
        obj.ParametersList = bui.Selector(obj.ParamTopBox, sets);
        obj.ParametersList.addlistener('SelectionChanged', @(src,event)...
          obj.paramProfileChanged(src, event));
        uix.Empty('Parent', obj.ParamTopBox);
      end
      
      if ~isempty(obj.ParamEditor) % delete existing parameters control
        clear(obj.ParamEditor);
      end
      
      % switch-case for how to load parameters for either: 1) default Exp
      % Def parameters; 2) Subject's last parameters; 3) Saved parameter
      % set on server
      switch lower(profile)
        case '<defaults>'
          paramStruct = exp.inferParameters(obj.ExpDefPath);
        case '<last for subject>'
          if isempty(obj.Subject)
            warning('No subject selected; loading Exp Def <defaults>');
            obj.ParametersList.SelectedIdx = 1; % changes selection in GUI and loads '<defaults>'
          end
          % list of all subject's experiments, with most recent first
          refs = flipud(dat.listExps(obj.Subject));
          % make sure we only "match" with *signals* experiments (as opposed to any other 'Worlds')
          matchTypes = {'custom', obj.ExpDefPath};
          % function takes parameters and returns true if of selected type
          matching = @(pars) iff(isfield(pars, 'defFunction'),...
            @()any(strcmpi(pick(pars, 'defFunction'), matchTypes)),... 
            false);
          % create a sequence of the parameters of each experiment
          paramsSeq = sequence(refs, @dat.expParams);
          % get the first (most recent) parameters whose type matches
          [paramStruct, ~] = paramsSeq.filter(matching).first;
          if isempty(paramStruct) % couldn't find a saved set of parameters for *signals* experiments for the subject
            warning(['No last saved Parameters found for subject "%s"\n'...
              'Please select another set of parameters.'], obj.Subject);
            return;
          end
        otherwise
          if isempty(obj.Subject)
            warning('No subject selected; loading Exp Def <defaults>');
            obj.ParametersList.SelectedIdx = 1; % changes selection in GUI and loads '<defaults>'
          end
          saved = dat.loadParamProfiles('custom');
          paramStruct = saved.(profile);
      end
      
      if isfield(paramStruct, 'services') % remove 'services' field
        paramStruct = rmfield(paramStruct, 'services');
      end
      
      obj.Parameters.Struct = paramStruct; % set parameters to ExpTest object
      if isempty(paramStruct); return; end
      % Now parameters are loaded, pass to ParamEditor for display, etc.
      if isempty(obj.ParamEditor)
        obj.ParamEditor = eui.ParamEditor(obj.Parameters, obj.ParamBottomBox); % Build parameter list in Global panel by calling eui.ParamEditor
      else
        obj.ParamEditor.buildUI(obj.Parameters);
      end
      obj.ParamEditor.addlistener('Changed', @(src,event) obj.paramProfileChanged(src, event));
      
      % construct an Exp Ref
      if isempty(obj.Subject) % construct a default expRef just so we can run experiment
        obj.Parameters.Struct.expRef = dat.constructExpRef('N/A',... 
          now, 1);
      else
        obj.Parameters.Struct.expRef = dat.constructExpRef(obj.Subject,... 
          now, 1);
      end
      
      % prettify 'ParamGrid'
      obj.ParamGrid.set('Heights', [-1 -6]);
    end
    
    function setPTB(obj)
      % sets necessary PsychToolBox and visual element settings for running Exp Def
      
      % if the ScreenH has yet to be initialized, or it doesn't correspond
      % to any currently open Screens
      if isempty(obj.ScreenH) || ~isequal(obj.ScreenH, Screen('Windows'))
        addSignalsJava; % add paths for necessary java classes
        InitializeMatlabOpenGL; % initialize MOGL for PTB use
        global GL GLU AGL %#ok<*TLEV,NUSED> initialize vars needed by MOGL subroutines
        
        % initialize PTB Screen
        nScreens = Screen('Screens');
        screenNum = iff(nScreens(end) >= 2, 1, 0);
        obj.ScreenH = Screen('OpenWindow', screenNum, 0, [0,0,960,400], 32); %1280, 600
        Screen('FillRect', obj.ScreenH, 255/2);
        Screen('Flip', obj.ScreenH);
      end
    end
    
  end
  
  methods (Static = true)
    function checkForUpdate(~)
      
      % get paths to check for updates
      curDir = pwd;
      rigboxPath = fileparts(which('addRigboxPaths'));
      signalsPath = fileparts(which('addSignalsPaths'));
      paths = {rigboxPath; signalsPath};
      
      % Get the path to the Git exe
      gitexepath = getOr(dat.paths, 'gitExe');
      if isempty(gitexepath)
        [status, gitexepath] = system('where git');
        if status == 1
          error(['Could not find the git .exe location. Please find and ',...
            'add the location to the "dat.paths" file. For example, like so:',...
            ' p.gitExe = ''C:\Program Files\Git\cmd\git.exe''']);
        end
      end
      gitexepath = ['"', strtrim(gitexepath), '"'];
      
      % check for updates for each path
      for i = 1:length(paths)
        cd(paths{i});
        
        % git fetch
        system([gitexepath, ' fetch']);
        
        % git status
        [~, status] = system([gitexepath, ' status']);
        
        % if remote branch is ahead, ask to update
        if contains(status, 'up to date')
          continue;
        else
          [~, curBranch] = ...
            system([gitexepath, ' rev-parse --abbrev-ref HEAD']);
          curBranch = strtrim(curBranch);
          q = ['Your ' paths{i} ' ' '"' curBranch '"',... 
            ' is currently behind the remote branch, would you like to '...
            'update?'];
          t = 'Update repository?';
          qAns = questdlg(q,t);
          if strcmpi(qAns, 'yes') % then stash and pull
            cmdstrStash = [gitexepath,...
              ' stash push -m "stash WIP for git update by ExpTestPanel"'];
            cmdstrPull = [gitexepath, ' pull'];
            system(cmdstrStash, '-echo');
            system(cmdstrPull, '-echo');
          else
            continue
          end
        end
      end
      cd(curDir);
    end
 
    
  end

  
end
