function [layer, img] = circLayer(pos, dims, orientation)
%VIS.CIRCLAYER Return texture layer for producing a circle
%  Creates a circle stimulus and a texture layer for producing the image in
%  Signals.
%  
%  Inputs:
%    pos - texture offset defined as [azimuth altitude] in visual degrees
%    dims - dimentions of circle/ellipse as [major axis, minor axis] in 
%      visual degrees.  If scalar is given, this is taken to be the
%      diameter of the circle. Currently this can not be a Signal.
%    orientation - orientation of texture in degrees
%
%  Outputs:
%    layer - the texture layer containing information about the texture,
%      e.g. size, position, orientation
%    img - the texture image as a 2D array of pixel intensity values
%      between 0 and 1
%
%  See also VIS.PATCH, VIS.RECTLAYER, VIS.EMPTYLAYER

%% Layer properties
% Use empty texture layer as template
layer = vis.emptyLayer();
% Linear interpolation smooths contour when scaled
layer.interpolation = 'linear';
% Set the position and orientation of the texture
layer.texOffset = pos;
layer.texAngle = orientation;
% Scale texture to the desired dimentions
layer.size = dims;
% Ensure texture is not repeated across the screen
layer.isPeriodic = false;

%% Circle
% Image must not be a Signal so choose a reasonable value for the texture
if isa(dims, 'sig.Signal'), dims = 500; end
% If only one value is given for dimentions, replicate value for both axes
if length(dims) == 1, dims = [dims dims]; end
% Set the extent of blurring at the border of the circle between 0 and 1.  
% This is comprable to anti-aliasing the circle
border = 0.05;

% Upsample the shape according to an exponential function, that is create a
% bigger texture then shrink it down.  The bigger the specified dimentions,
% the less upsampling is required. 
% FIXME: there may be a better way of determining this.
% FIXME: Rename radius
radius = round(dims(1) * (0.9^(dims(1)-23)+1));
y = round(dims(2) * (0.9^(dims(2)-23)+1));

% Create meshgrid with which to produce curve
[xx, yy] = meshgrid(colon(1,radius), colon(1,y));
dd = sqrt(xx.^2 + yy.^2);
img = taper(dd) + taper(-dd) - 1; % Border anti-aliasing
img = [rot90(img,2), flipud(img); fliplr(img), img]; % Put quarters together
img = single(img);
  function y = taper(x)
    % Applies a tapering function to the matrix x
    %  Creates a normalized image containing a curve of a given radius and
    %  a soft border defined as the proportion of the image FIXME: Clarify
    y = -2*(x - radius*(1 - 0.5*border))./(radius*border);
    % Normalize values between 0 and 1
    y = 0.5*(erf(y) + 1);
  end

end