function elem = grid(t)
% VIS.GRID Returns a Signals grid stimulus
%  Produces a visual element for parameterizing the presentation of a grid.
%
%  Inputs:
%    't' - The "time" signal. Used to obtain the Signals network ID.
%      (Could be any signal within the network - 't' is chosen by
%      convention).
%
%  Outputs:
%    'elem' - a subscriptable signal containing fields which parametrize
%      the stimulus, and a field containing the processed texture layer. 
%      Any of the fields may be a signal.
%
%  Stimulus parameters (fields belonging to 'elem'):
%    'azimuths' -
%    'altitudes' -
%    'thickness' -
%    'colour' -
%    'show' -
%
% See Also VIS.EMPTYLAYER, VIS.CHECKER6, VIS.PATCH, VIS.GRATING, VIS.IMAGE
%
% todo: add to documentation

elem = t.Node.Net.subscriptableOrigin('grid');
elem.azimuths = [-180 -90 0 90 180];
elem.altitudes = [-90 0 90];
elem.thickness = 2;
elem.colour = [102 153 255]/255;
elem.show = false;
elem.layers = elem.map(@makeLayers).flattenStruct();

  function layers = makeLayers(newelem)
    clear elem t; % eliminate references to unused outer variables
    % columns
    colsize = [newelem.thickness 180];
    for li = 1:numel(newelem.azimuths)
        [layer, img] = vis.rectLayer(...
          [newelem.azimuths(li); 0],...
          colsize, 0);
        [layer.rgba, layer.rgbaSize] = vis.rgba(1, 0.5*img);
        layer.textureId = 'transparentPixel';
        layer.blending = 'source';
        layer.maxColour = [newelem.colour 1];
        layer.show = newelem.show;
        layers(li) = layer;
    end
    % rows
    rowsize = [360 newelem.thickness];
    for li = 1:numel(newelem.altitudes)
      [layer, img] = vis.rectLayer(...
        [0; newelem.altitudes(li)],...
        rowsize, 0);
      [layer.rgba, layer.rgbaSize] = vis.rgba(1, img);
      layer.textureId = 'square';
      layer.blending = 'source';
      layer.maxColour = [newelem.colour 1];
      layer.show = newelem.show;
      layers(end+1) = layer;
    end
  end

end