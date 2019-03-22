function [t, setgraphic, curser] = playgroundPTB(title, parent)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
%equivalent to exp.SignalsExp
global AGL GL GLU
InitializeMatlabOpenGL
if nargin < 1
  title = 'Signals playground';
end

if nargin < 2
  parent = figure('Name', title, 'NumberTitle', 'off',...
    'Toolbar', 'none', 'Menubar', 'none');
end

set(bui.parentFigure(parent), 'DeleteFcn', @cleanup);

tmr = timer('ExecutionMode', 'fixedSpacing', 'Period', 5e-3,...
  'TimerFcn', @process, 'Name', 'MainLoop');
cp = hw.CursorPosition;

vbox = uix.VBox('Parent', parent);

% Get number of available screens
nScreens = Screen('Screens');
screenNum = iff(max(nScreens) > 2, 1, 0);
vc = Screen('OpenWindow', screenNum, 0, [0,0,1280,600], 32);
Screen('FillRect', vc, 255/2);
Screen('Flip', vc);

btnbox = uix.HBox('Parent', vbox);
vbox.Sizes = 30;
btnh = uicontrol('Parent', btnbox, 'Style', 'pushbutton',...
  'String', 'Play', 'Callback', @(~,~)startstop());

sn = sig.Net;
dt = sn.origin('dt');
t = dt.scan(@plus, 0);
t.Name = 'time';
curser = sn.origin('curser');

tlast = [];
listhandle = [];
textureById = containers.Map('KeyType', 'char', 'ValueType', 'uint32');
layersByName = containers.Map();
model = vis.init(vc);

screenDimsCm = [20 25]; %[width_cm heigh_cm]
pxW = 1280/3;
pxH = 600;
screens(1) = vis.screen([0 0 9.5], -90, screenDimsCm, [0 0 pxW pxH]);        % left screen
screens(2) = vis.screen([0 0 10],  0 , screenDimsCm, [pxW 0 2*pxW pxH]);    % ahead screen
screens(3) = vis.screen([0 0 9.5],  90, screenDimsCm, [2*pxW  0 3*pxW pxH]); % right screen
model.screens = screens;
invalid = false;

setgraphic = @setElements;

running = false;
% while running
%   pause(10e-3);
% end

renderCount = 0;

  function startstop()
    if running
      running = false;
      stop(tmr);
      set(btnh, 'String', 'Play');
    else
      tlast = GetSecs;
      running = true;
      start(tmr);
      set(btnh, 'String', 'Pause');
    end
  end

  function process(~,~)
    tnow = GetSecs;
%     tic
    post(dt, tnow - tlast);
    post(curser, GetMouse());
%     post(curser, readAbsolutePosition(cp));
%     fprintf('%.0f\n', 1000*toc);
    tlast = tnow;
    runSchedule(sn);
    if invalid
      layerValues = cell2mat(layersByName.values());
      Screen('BeginOpenGL', vc);
      vis.draw(vc, model, layerValues, textureById);
      Screen('EndOpenGL', vc);
      Screen('Flip', vc, 0);
      renderCount = renderCount + 1;
      invalid = false;
    end
  end

  function cleanup(~,~)
    stop(tmr);
    delete(tmr);
    try
      close('LivePlot')
    catch
    end
    t.end(t.Node.Id, 1)
    dt.end(dt.Node.Id, 1)
    % delete gl textures
    listhandle = [];
    tex = cell2mat(textureById.values);
    fprintf('Deleting %i textures\n', numel(tex));
    Screen('AsyncFlipEnd', vc);
    Screen('BeginOpenGL', vc);
    glDeleteTextures(numel(tex), tex);
    textureById.remove(textureById.keys);
    Screen('EndOpenGL', vc);
    Screen('CloseAll');
    sn.delete();
  end

  function setElements(elems)
    rfgrid = vis.grid(t);
    elems.rfgrid = rfgrid;
    listhandle = [];
    fields = fieldnames(elems);
    for fi = 1:numel(fields)
      layersSig = elems.(fields{fi}).Node.CurrValue.layers;
      listhandle = [listhandle
        layersSig.onValue(fun.partial(@newLayerValues, fields{fi}))];
      newLayerValues(fields{fi}, layersSig.Node.CurrValue);
%       fn = fields{fi};
%       layerSig = elems.(fn).Node.CurrValue.layers;
%       listhandle = [listhandle; layerSig.onValue(@(v)newLayers(fn, v))];
% %       elems.(fn).post(elems.(fn).Node.CurrValue); % ugly hack to refresh
    end
    rfgrid.show = true;
  end

  function newLayerValues(name, l)
      if isKey(layersByName, name)
        prev = layersByName(name);
        prevshow = any([prev.show]);
      else
        prevshow = false;
      end
      layersByName(name) = l;

      if any([l.show]) || prevshow
        invalid = true;
      end
%     if ~isempty(l)
%       layersByName.(name) = l;
%       alllayers = struct2cell(layersByName);
%       alllayers = horzcat(alllayers{:});
% %       vc.setLayers(struct2cell(alllayers')');
% %       %% load textures
% %       layerData = obj.LayersByStim(name);
%       Screen('BeginOpenGL', vc);
%       try
%         vis.loadLayerTextures(alllayers);
%       catch glEx
%         Screen('EndOpenGL', vc);
%         rethrow(glEx);
%       end
%       Screen('EndOpenGL', vc);
%       invalid = true;
%     end
  end

end

