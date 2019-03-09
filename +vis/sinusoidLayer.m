function [layer, img] = sinusoidLayer(azimuth, spatialFreq, phase, orientation)
% VIS.SINUSOIDLAYER Return a texture layer and image for a sinusoid
%  Creates a sinusoid stimulus and a texture layer for producing a grating
%  in Signals.
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
%  See also VIS.SQUAREWAVELAYER, VIS.EMPTYLAYER, VIS.GRATING

%%% (co)sinusoid of unit wavelength, from 0 to 1: 0.5*cos( 2*pi*x ) + 0.5
% If a single of cycle of a sinsusoid is sampled at 37 equally spaced
% points, linear interpolation between adjacent samples will have a max
% error < 0.5/255.
% An odd number means we hit the peak of the sinusoid == 1 at the centre
% pixel.
%
% So sample a full cycle at that resolution, changing along the x-axis, and
% only 1 sample tall in y.
np = 37;
p = single(linspace(-0.5, 0.5 - 1/np, np));
img = 0.5*cos(2*pi*p) + 0.5;

% width is dependent on spatial frequency (SF)
w = 1/spatialFreq;

% azimuth is dependent on SF, phase, and orientation
azi = (180*mod(phase,2*pi)/pi)/(spatialFreq*360) +... 
  azimuth*cos(deg2rad(orientation));

layer = vis.emptyLayer();
% layer.image = img;
layer.texOffset = [azi; 0];
layer.texAngle = orientation;
% it's full field by being periodic
layer.size = [w; 180];% full altitude coverage
layer.isPeriodic = true;

end

