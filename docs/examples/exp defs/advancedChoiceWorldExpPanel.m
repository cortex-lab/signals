classdef advancedChoiceWorldExpPanel < eui.SignalsExpPanel
  % UI control for monitoring advancedChoiceWorld
  %   A UI panel that plots experiment updates specific to the
  %   advancedChoiceWorld signals experiment definition.  Plots a
  %   psychometric curve for each of the three response types, along with
  %   a simulation of the current stimulus window and stimulus position
  %   with respect to the response thresholds.
  %
  % See also eui.SignalsExpPanel
  %
  % Part of Rigbox
    
  properties (Access = private)
    RewardUnits = sprintf('%cl', char(956)) % Units of the reward output
    PsychometricAxes % Handle to axes of psychometric plot
    ExperimentAxes % Handle to axes of wheel trace and threhold line plot
    ExperimentHands % Handles to plot objects in the experiment axes
    ScreenAxes
    ScreenHands
    VelAxes
    VelHands
    InputSensorPosTime % Vector of timesstamps in seconds for plotting the wheel trace
    InputSensorPos % Vector of azimuth values for plotting the wheel trace
    InputSensorPosCount = 0 % Running total of azimuth samples recieved for axes plot
    ExtendThresholdLines = false % Flag for plotting dotted threshold lines during cue interactive delay.  Currently unused.
    lastEvtTime = now;
  end
  
  methods
    function obj = advancedChoiceWorldExpPanel(parent, ref, params, logEntry)
      obj = obj@eui.SignalsExpPanel(parent, ref, params, logEntry);
      % Initialize InputSensor properties for speed
      obj.InputSensorPos = nan(1000*30, 1);
      obj.InputSensorPosTime = nan(1000*30, 1);
      obj.InputSensorPosCount = 0;
      obj.Block.numCompletedTrials = -1; % Store sum of events.newTrial
      obj.Block.totalReward = 0; % Store sum of outputs.reward event here
      obj.Block.trial = struct('contrastLeft', [], 'contrastRight', [], ...
        'response', [], 'repeatNum', [], 'feedback', [], 'pars', []);
      % Set which events we wish to display as info fields
      exclude = ["inputs.wheelDeg", "events.expStart", "events.newTrial", "events.contrast"];
      obj.UpdatesFilter = [obj.UpdatesFilter, exclude];
      % Prettify the InfoLabels
      obj.FormatLabels = true;
      % Add our reward info field.  Unlike TrialCountLabel we keep this in
      % the LabelsMap so that it updates green when changing
      obj.LabelsMap('outputs.reward') = obj.addInfoField('Reward', ['0 ' obj.RewardUnits]);
      set(obj.LabelsMap('outputs.reward'), 'UserData', clock);
    end
    
  end
  
  methods (Access = protected)
    
    function processUpdates(obj)
      updates = obj.SignalUpdates(1:obj.NumSignalUpdates);
      obj.NumSignalUpdates = 0;
      
      if ~isempty(updates)
        %fprintf('processing %i signal updates\n', length(updates));
        
        
        % pull out wheel updates
        allNames = {updates.name};
        wheelUpdates = strcmp(allNames, 'inputs.wheelMM');
        
        if sum(wheelUpdates)>0
          
          x = -[updates(wheelUpdates).value];
          t = (24*3600*cellfun(@(x)datenum(x), {updates(wheelUpdates).timestamp}))-(24*3600*obj.StartedDateTime);
          
          nx = numel(x);
          obj.InputSensorPosCount = obj.InputSensorPosCount+nx;
          
          if obj.InputSensorPosCount>numel(obj.InputSensorPos)
            % full - drop the first half of the array and shift the
            % last half back
            halfidx = floor(numel(obj.InputSensorPos)/2);
            obj.InputSensorPos(1:halfidx) = obj.InputSensorPos(halfidx:2*halfidx-1);
            obj.InputSensorPos(halfidx+1:end) = NaN;
            obj.InputSensorPosTime(1:halfidx) = obj.InputSensorPosTime(halfidx:2*halfidx-1);
            obj.InputSensorPosTime(halfidx+1:end) = NaN;
            obj.InputSensorPosCount = obj.InputSensorPosCount-halfidx;
          end
          obj.InputSensorPos(obj.InputSensorPosCount-nx+1:obj.InputSensorPosCount) = x;
          obj.InputSensorPosTime(obj.InputSensorPosCount-nx+1:obj.InputSensorPosCount) = t;
          
        end
        
        % now plot the wheel
        plotwindow = [-5 1];
        lastidx = obj.InputSensorPosCount;
        
        if lastidx>0
          
          firstidx = find(obj.InputSensorPosTime>obj.InputSensorPosTime(lastidx)+plotwindow(1),1);
          
          xx = obj.InputSensorPos(firstidx:lastidx);
          tt = obj.InputSensorPosTime(firstidx:lastidx);
          
          set(obj.ExperimentHands.wheelH,...
            'XData', xx,...
            'YData', tt);
          
          set(obj.ExperimentAxes.Handle, 'YLim', plotwindow + tt(end));
          
          if numel(xx) > 1
            % update the velocity tracker too
            [tt, idx] = unique(tt);
            recentX = interp1(tt, xx(idx), tt(end)+(-0.3:0.05:0));
            vel = mean(diff(recentX));
            set(obj.VelHands.Vel, 'XData', vel*[1 1]);
            obj.VelHands.MaxVel = max(abs([obj.VelHands.MaxVel vel]));
            set(obj.VelAxes, 'XLim', obj.VelHands.MaxVel*[-1 1]);
          end
        end
        
        
        % now deal with other updates
        updates = updates(~wheelUpdates);
        allNames = allNames(~wheelUpdates);
        
        % first check if there is an events.newTrial
        if any(strcmp(allNames, 'events.newTrial'))
          
          obj.Block.numCompletedTrials = obj.Block.numCompletedTrials+1;
          
          % Step 1: finish up the last trial
          obj.PsychometricAxes.clear();
          if obj.Block.numCompletedTrials > 2
            psy.plot2AUFC(obj.PsychometricAxes.Handle, obj.Block);
          end
          
          % make sure we have all necessary data about new trial
          assert(all(ismember(...
            {'events.trialNum', 'events.repeatNum', 'pars'}, allNames)), ...
            'exp panel did not find all the required data about the new trial!');
          
          % pull out the things we need to keep
          trNum = updates(strcmp(allNames, 'events.trialNum')).value;
          %assert(trNum==obj.Block.numCompletedTrials+1, 'trial number doesn''t match');
          if ~(trNum==obj.Block.numCompletedTrials+1)
            fprintf(1, 'trial number mismatch: %d, %d\n', trNum, obj.Block.numCompletedTrials+1);
            obj.Block.numCompletedTrials = trNum-1;
          end
          
          obj.Block.trial(trNum).repeatNum = ...
            updates(strcmp(allNames, 'events.repeatNum')).value;
          
          p = updates(strcmp(allNames, 'pars')).value;
          obj.Block.trial(trNum).pars = p;
          cL = p.stimulusContrast(1); cR = p.stimulusContrast(2);
          obj.Block.trial(trNum).contrastLeft = cL;
          obj.Block.trial(trNum).contrastRight = cR;
          
        end
        
        
        for ui = 1:length(updates)
          signame = updates(ui).name;
          switch signame
            
            case 'events.interactiveOn'
              
              % re-set the response window starting now
              ioTime = (24*3600*datenum(updates(ui).timestamp))-(24*3600*obj.StartedDateTime);
              
              p = obj.Block.trial(end).pars;
              cL = p.stimulusContrast(1); cR = p.stimulusContrast(2);
              
              % update wheel plot to show thresholds
              if cL>0 && cL>cR
                colorL = 'g'; colorR = 'r';
              elseif cL>0 && cL==cR
                colorL = 'g'; colorR = 'g';
              elseif cR>0
                colorL = 'r'; colorR = 'g';
              else
                colorL = 'r'; colorR = 'r';
              end
              
              respWin = p.responseWindow; if respWin>1000; respWin = 1000; end
              
              th = p.stimulusAzimuth/p.wheelGain;
              startPos = obj.InputSensorPos(find(obj.InputSensorPosTime<ioTime,1,'last'));
              if isempty(startPos); startPos = obj.InputSensorPos(obj.InputSensorPosCount); end % for first trial
              tL = startPos-th;
              tR = startPos+th;
              
              set(obj.ExperimentHands.threshL, 'Color', colorL, ...
                'XData', [tL tL], 'YData', ioTime+[0 respWin]);
              set(obj.ExperimentHands.threshR, 'Color', colorR, ...
                'XData', [tR tR], 'YData', ioTime+[0 respWin]);
              
              yd = get(obj.ExperimentHands.threshLoff, 'YData');
              set(obj.ExperimentHands.threshLoff, 'XData', [tL tL], 'YData', [yd(1) ioTime]);
              set(obj.ExperimentHands.threshRoff, 'XData', [tR tR], 'YData', [yd(1) ioTime]);
              
              obj.ExperimentAxes.XLim = startPos+1.5*th*[-1 1];
              
            case 'events.stimulusOn'
              
              p = obj.Block.trial(end).pars;
              soTime = (24*3600*datenum(updates(ui).timestamp))-(24*3600*obj.StartedDateTime);
              
              th = p.stimulusAzimuth/p.wheelGain;
              startPos = obj.InputSensorPos(find(obj.InputSensorPosTime<soTime,1,'last'));
              if isempty(startPos); startPos = obj.InputSensorPos(obj.InputSensorPosCount); end % for first trial
              tL = startPos-th;
              tR = startPos+th;
              
              set(obj.ExperimentHands.threshLoff,  ...
                'XData', [tL tL], 'YData', soTime+[0 100]);
              set(obj.ExperimentHands.threshRoff, ...
                'XData', [tR tR], 'YData', soTime+[0 100]);
              set(obj.ExperimentHands.threshL, 'YData', [NaN NaN]);
              set(obj.ExperimentHands.threshR, 'YData', [NaN NaN]);
              
              set(obj.ExperimentHands.incorrIcon, 'XData', 0, 'YData', NaN);
              set(obj.ExperimentHands.corrIcon, 'XData', 0, 'YData', NaN);
              
              obj.ExperimentAxes.XLim = startPos+1.5*th*[-1 1];
              
              if ~isempty(obj.ScreenAxes)
                % show the visual stimulus
                [x,y,im] = screenImage(p);
                set(obj.ScreenHands.Im, 'XData', x, 'YData', y, 'CData', im);
                caxis(obj.ScreenAxes, [0 255]);
              end
              
            case 'events.stimulusOff'
              if ~isempty(obj.ScreenAxes)
                set(obj.ScreenHands.Im, 'CData', 127*ones(size(get(obj.ScreenHands.Im, 'CData'))));
                caxis(obj.ScreenAxes, [0 255]);
              end
            case 'events.response'
              
              obj.Block.trial(obj.Block.numCompletedTrials+1).response = updates(ui).value;
              
            case 'events.feedback'
              
              obj.Block.trial(obj.Block.numCompletedTrials+1).feedback = updates(ui).value;
              
              fbTime = (24*3600*datenum(updates(ui).timestamp))-(24*3600*obj.StartedDateTime);
              whIdx = find(obj.InputSensorPosTime<fbTime,1, 'last');
              
              if updates(ui).value > 0
                set(obj.ExperimentHands.corrIcon, ...
                  'XData', obj.InputSensorPos(whIdx), ...
                  'YData', obj.InputSensorPosTime(whIdx));
                set(obj.ExperimentHands.incorrIcon, ...
                  'XData', 0, ...
                  'YData', NaN);
              else
                set(obj.ExperimentHands.incorrIcon, ...
                  'XData', obj.InputSensorPos(whIdx), ...
                  'YData', obj.InputSensorPosTime(whIdx));
                set(obj.ExperimentHands.corrIcon, ...
                  'XData', 0, ...
                  'YData', NaN);
              end
              
            case 'events.azimuth'
              
              az = updates(ui).value;
              if ~isempty(obj.ScreenAxes)
                % trick to move visual stimuli by moving the xlim in the opposite way
                set(obj.ScreenAxes, 'XLim', -az+[-135 135]); 
              end
              
            case 'events.trialNum'
              set(obj.TrialCountLabel, ...
                'String', num2str(updates(ui).value));
              
            case 'outputs.reward'
              % Keep track of total reward and display both
              obj.Block.totalReward = obj.Block.totalReward + updates(ui).value;
              str = sprintf('%.1f%s (%.1f%s)', ...
                obj.Block.totalReward, obj.RewardUnits, ...
                updates(ui).value, obj.RewardUnits);
              set(obj.LabelsMap(signame), 'String', str, 'UserData', clock,...
                'ForegroundColor', obj.RecentColour);
              
            otherwise
              % For any custom updates that pass the UpdatesFilter, simply
              % display their values
              onList = any(ismember(signame, obj.UpdatesFilter));
              if (obj.Exclude && ~onList) || (~obj.Exclude && onList)
                if ~isKey(obj.LabelsMap, signame) % If new update, add field
                  obj.LabelsMap(signame) = obj.addInfoField(signame, '');
                end
                str = toStr(updates(ui).value); % Convert the value to string
                set(obj.LabelsMap(signame), 'String', str, 'UserData', clock,...
                  'ForegroundColor', obj.RecentColour); % Update value
              end
          end
        end
        
      end
    end
        
    function build(obj, parent)
      build@eui.SignalsExpPanel(obj, parent);
      
      % Build the psychometric axes
      plotgrid = uiextras.VBox('Parent', obj.CustomPanel, 'Padding', 5);
      
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      
      obj.PsychometricAxes = bui.Axes(plotgrid);
      obj.PsychometricAxes.ActivePositionProperty = 'position';
      obj.PsychometricAxes.YLim = [-1 101];
      obj.PsychometricAxes.NextPlot = 'add';
      obj.PsychometricAxes.Title = 'Pyschometric plot';
      obj.PsychometricAxes.xLabel('Contrast');
      yyaxis(obj.PsychometricAxes.Handle,'left')
      set(obj.PsychometricAxes.Handle, 'YColor', [0 .8 .8])
      obj.PsychometricAxes.yLabel('% Leftward');
      yyaxis(obj.PsychometricAxes.Handle,'right')
      set(obj.PsychometricAxes.Handle, 'YColor', 'm')
      obj.PsychometricAxes.yLabel('% Rightward');
      
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      
      % The function screenImage used for the Screen plot requires the
      % Image Processing Toolbox.  If this isn't present, deactivate the
      % axes
      toolboxes = ver;
      required = {'Image Processing', 'Statistics and Machine Learning'};
      installed = ismember(strcat(required,' Toolbox'), {toolboxes.Name});
      if ~all(installed)
        % Toolbox(es) not found
        warning('Rigbox:eui:choiceExpPanel:toolboxRequired', ...
        'The %s is required for full functionality', ...
        strjoin(strcat(required(~installed),' Toolbox'), ' and '))
        scH = [];
      else % Create screen image plot
        obj.ScreenAxes = axes('Parent', plotgrid);
        obj.ScreenHands.Im = imagesc(0,0,127);
        axis(obj.ScreenAxes, 'image');
        axis(obj.ScreenAxes, 'off');
        colormap(obj.ScreenAxes, 'gray');
        scH = -2;
      end
      
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      
      obj.ExperimentAxes = bui.Axes(plotgrid);
      obj.ExperimentAxes.ActivePositionProperty = 'position';
      obj.ExperimentAxes.XTickLabel = [];
      obj.ExperimentAxes.NextPlot = 'add';
      obj.ExperimentHands.wheelH = plot(obj.ExperimentAxes,...
        [0 0],...
        [NaN NaN],...
        'Color', .75*[1 1 1]);
      obj.ExperimentHands.threshL = plot(obj.ExperimentAxes, ...
        [0 0],...
        [NaN NaN],...
        'Color', [1 1 1], 'LineWidth', 4);
      obj.ExperimentHands.threshR = plot(obj.ExperimentAxes, ...
        [0 0],...
        [NaN NaN],...
        'Color', [1 1 1], 'LineWidth', 4);
      obj.ExperimentHands.threshLoff = plot(obj.ExperimentAxes, ...
        [0 0],...
        [NaN NaN],...
        'Color', [0.5 0.5 0.5], 'LineWidth', 4);
      obj.ExperimentHands.threshRoff = plot(obj.ExperimentAxes, ...
        [0 0],...
        [NaN NaN],...
        'Color', [0.5 0.5 0.5], 'LineWidth', 4);
      obj.ExperimentHands.corrIcon = scatter(obj.ExperimentAxes, ...
        0, NaN, pi*10^2, 'b', 'filled');
      obj.ExperimentHands.incorrIcon = scatter(obj.ExperimentAxes, ...
        0, NaN, pi*10^2, 'rx', 'LineWidth', 4);
      
      uiextras.Empty('Parent', plotgrid, 'Visible', 'off');
      
      obj.VelAxes = axes('Parent', plotgrid);
      obj.VelHands.Zero = plot(obj.VelAxes, [0 0], [0 1], 'k--');
      hold(obj.VelAxes, 'on');
      obj.VelHands.Vel = plot(obj.VelAxes, [0 0], [0 1], 'r', 'LineWidth', 2.0);
      axis(obj.VelAxes, 'off');
      obj.VelHands.MaxVel = 1e-9;
      
      set(plotgrid, 'Sizes', [30 -2 30 scH 10 -4 5 -1]);
    end
  end
  
end

