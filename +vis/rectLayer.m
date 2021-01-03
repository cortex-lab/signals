function [layer, img] = rectLayer(pos, dims, orientation)
%VIS.RECTLAYER Return texture layer for producing a rectangle
%  Creates a simple rectangle stimulus and a texture layer for producing
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

%% Square
% Create a 3x3 matrix with the centre pixle set to 1.  This single square
% pixel can be transformed to create a rectangle of any dimensions.
img = zeros(3, 3, 'single');
img(2,2) = 1;

%% Layer
% Now create a texture layer to store the information about size, etc.
% Use an empty layer as a template structure
layer = vis.emptyLayer();
% Use nearest neighbour interpolation so that borders of rectangle remain
% sharp when image is expanded
layer.interpolation = 'nearest';
% Set the postion and orientation of the texture
layer.texOffset = pos;
layer.texAngle = orientation;
% As the image is one pixel in a 3-by-3 matrix, set the size to be 3x the
% input dimentions
layer.size = 3*dims;
% Ensure texture is not repeated across the screen
layer.isPeriodic = false;

end