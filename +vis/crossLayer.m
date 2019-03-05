function [layer, img] = crossLayer(pos, dims, orientation)
%VIS.CROSSLAYER Return texture layer for producing a cross
%  Creates a simple cross stimulus and a texture layer for producing
%  the image in Signals. 
%  
%  Inputs:
%    pos - texture offset defined as [azimuth altitude] in visual degrees
%    dims - dimentions of rectangle as [width height] in visual degrees
%    orientation - orientation of texture in degrees
%
%  Outputs:
%    layer - the texture layer containing information about the texture,
%      e.g. size, position, orientation
%    img - the texture image as a 2D array of pixel intensity values
%      between 0 and 1
%
%  See also VIS.PATCH, VIS.CIRCLAYER, VIS.EMPTYLAYER

%% cross
img = zeros(3, 3, 'single');
img(:,2) = 1; img(2,:) = 1;

layer = vis.emptyLayer();
layer.interpolation = 'nearest';
layer.texOffset = pos;
layer.texAngle = orientation;
layer.size = dims;
layer.isPeriodic = false;

end