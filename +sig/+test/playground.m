function [t, setgraphic] = playground(title, parent)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
%equivalent to exp.SignalsExp

if nargin < 1
  title = 'Signals playground';
end

if nargin < 2
  parent = figure('Name', title, 'NumberTitle', 'off',...
    'Toolbar', 'none', 'Menubar', 'none');
end

set(bui.parentFigure(parent), 'DeleteFcn', @cleanup);

tmr = timer('ExecutionMode', 'fixedSpacing', 'Period', 5e-3,...
  'TimerFcn', @process);

vbox = uix.VBox('Parent', parent);

[vc, vcc] = vis.component(vbox.UIContainer); %error with java: no JOGL
vc.clearColour([0.5 0.5 0.5 1]);

btnbox = uix.HBox('Parent', vbox);
vbox.Sizes = [-1 30];
btnh = uicontrol('Parent', btnbox, 'Style', 'pushbutton',...
  'String', 'Play', 'Callback', @(~,~)startstop());

sn = sig.Net;
dt = sn.origin('dt');
t = dt.scan(@plus, 0);

tlast = [];
listhandle = [];
layersByName = struct;

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
%     fprintf('%.0f\n', 1000*toc);
    tlast = tnow;
    runSchedule(sn);
    if invalid
      vc.display();
      renderCount = renderCount + 1;
      invalid = false;
    end
  end

  function cleanup(~,~)
    stop(tmr);
    delete(tmr);
    sn.delete();
  end

  function setElements(elems)
    rfgrid = vis.grid(t);
    elems.rfgrid = rfgrid;
    listhandle = [];
    layersByName = struct;
    fields = fieldnames(elems);
    for fi = 1:numel(fields)
      fn = fields{fi};
      layerSig = elems.(fn).Node.CurrValue.layers;
      listhandle = [listhandle; layerSig.onValue(@(v)newLayers(fn, v))];
%       elems.(fn).post(elems.(fn).Node.CurrValue); % ugly hack to refresh
    end
    rfgrid.show = true;
  end

  function newLayers(name, l)
    if ~isempty(l)
      layersByName.(name) = l;
      alllayers = struct2cell(layersByName);
      alllayers = horzcat(alllayers{:});
      vc.setLayers(struct2cell(alllayers')');
      invalid = true;
    end
  end

end

