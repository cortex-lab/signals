function elem = grid(t)
% VIS.GRID Returns a Signals grid stimulus
%  Produces a visual element for parameterizing the presentation of a grid.
%  Uses VIS.RECTLAYER to create columns and rows, which are combined to
%  form a grid.
%
%  Inputs:
%    t - Any signal, used to obtain the Signals network ID.
%
%  Outputs:
%    elem - a subscriptable signal containing fields which parametrize
%      the stimulus, and a field containing the processed texture layer.
%      Any of the fields may be a signal.
%
%  Stimulus parameters (fields belonging to elem):
%    azimuths - a vector of azimuths, one for each vertical grid line
%    altitudes - a vector of altitudes, one for each horizontal grid line
%    thickness - the line thickness (a scalar value, also in visual degrees)
%    colour - an array defining the intensity of the red, green and blue
%      channels respectively. Values must be between 0 and 1.
%      Default [1 1 1]
%    show - a logical indicating whether or not the stimulus is visible.
%      Default false
%
% See Also VIS.EMPTYLAYER, VIS.RECTLAYER, VIS.CHECKER, VIS.PATCH, VIS.IMAGE

elem = t.Node.Net.subscriptableOrigin('grid');
elem.azimuths = [-180 -90 0 90 180];
elem.altitudes = [-90 0 90];
elem.thickness = 2;
elem.colour = [102 153 255]/255;
elem.show = false;

azimuths = elem.azimuths.flatten();
altitudes = elem.altitudes.flatten();
thickness = elem.thickness.flatten();
colour = elem.colour.flatten();
colour = map2(colour(:), 1, @vertcat); % RGBA column vector

templateLayers = thickness.map(@makeTemplates);
gridLayers = templateLayers.mapn(azimuths, altitudes, @makeLayers);
elem.layers = gridLayers.mapn(colour, elem.show.flatten, @updateFields);
end

%% Helper functions
function templates = makeTemplates(thickness)
colsize = [thickness 180];
[columnLayer, img] = vis.rectLayer([], colsize, 0);
[columnLayer.rgba, columnLayer.rgbaSize] = vis.rgba(1, 0.5*img);
columnLayer.textureId = 'column';
columnLayer.blending = 'source';

rowsize = [360 thickness];
[rowLayer, img] = vis.rectLayer([], rowsize, 0);
[rowLayer.rgba, rowLayer.rgbaSize] = vis.rgba(1, img);
rowLayer.textureId = 'row';
rowLayer.blending = 'source';

templates = [columnLayer rowLayer];
end

function layers = makeLayers(templates, azimuths, altitudes)
nCols = numel(azimuths);
nRows = numel(altitudes);

% columns
columnLayers = repmat(templates(1), 1, nCols);
% set positions
azimuths = mat2cell([azimuths(:), zeros(nCols,1)], ones(1,nCols));
[columnLayers.texOffset] = deal(azimuths{:});

% rows
rowLayers = repmat(templates(2), 1, nRows);
% set positions
altitudes = mat2cell([zeros(nRows,1), altitudes(:)], ones(1,nRows));
[rowLayers.texOffset] =  deal(altitudes{:});

layers = [columnLayers rowLayers];
end

function layers = updateFields(layers, colour, show)
[layers.maxColour] = deal(colour);
[layers.show] = deal(show);
end

