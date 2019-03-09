function [layer, img] = squareWaveLayer(azimuth, spatialFreq, phase,...
  orientation)
% VIS.SQUAREWAVELAYER Return a texture layer and image for a squarewave
%  Creates a squarewave stimulus and a texture layer for producing a
%  grating in Signals.
%
%  Inputs:
%    azimuth - the position of the grating in the azimuth (position of the
%      centre pixel in visual degrees)
%    spatialFreq - the spatial frequency of the grating in cycles per
%      visual degree
%    phase - the phase of the grating in visual degrees.  Default 0
%    orientation - orientation of texture in degrees
%
%  Outputs:
%    layer - the texture layer containing information about the texture,
%      e.g. size, position, orientation
%    img - the texture image as a 2D array of pixel intensity values
%      between 0 and 1
%
%  See also VIS.SINUSOIDLAYER, VIS.EMPTYLAYER, VIS.GRATING

% Square wave grating unit wavelength, from 0 to 1
img = [0 1];

% width is dependent on spatial frequency (SF)
w = 1/spatialFreq;

% azimuth is dependent on SF, phase, and orientation
azi = (180*mod(phase - pi/2, 2*pi)/pi)/(spatialFreq*360) +... 
  azimuth*cos(deg2rad(orientation));

layer = vis.emptyLayer();
layer.interpolation = 'nearest';
layer.texOffset = [azi; 0];
layer.texAngle = orientation;
% it's full field by being periodic
layer.size = [w; 180];% full altitude coverage
layer.isPeriodic = true;

end

