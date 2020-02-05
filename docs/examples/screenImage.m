function [x,y,im] = screenImage(varargin)
% SCREENIMAGE Reconstructs visual Gabor stimulus from parameters
%  Given a struct of parameters from a Signals experiment, produces an
%  image of the Gabor stimulus.
%
%  Inputs (Optional):
%    StimulusContrast (numerical): 2x1 array of left and right stimulus
%      contrast.  Default: [NaN, NaN]
%    SpatialFreq (numerical): the spatial frequency (Hz) of the stimuli.
%      May be scalar if both stimuli are the same.  Default: 1/15
%    StimulusOrientation (numerical): the stimulus orientation (degrees).  
%      May be scalar if both stimuli are the same.  Default: 0
%    Azimuth (numerical): the absolute azimuth of the stimuli.  Default: 35
%    Sigma (numerical): the sigma of the Gaussians.  Currently only stimuli
%      of the same size are supported.  Default: 7
%
%  Outputs:
%    x (numerical): The horizontal Gabor values
%    y (numerical): The vertical Gabor values
%    im (numerical): The image data
%
%  NB: Requires Image Processing Toolbox
%
% See also choiceWorldExpPanel
%
% 2017 NS created

p = inputParser;
p.addParameter('stimulusContrast', nan(2,1), @isnumeric)
p.addParameter('spatialFrequency', repmat(1/15,2,1), @isnumeric)
p.addParameter('stimulusOrientation', zeros(2,1), @isnumeric)
p.addParameter('stimulusAzimuth', 35, @isscalar)
p.addParameter('sigma', repmat(7,2,1), @isnumeric)
p.KeepUnmatched = true;

p.parse(varargin{:})
pars = struct2cell(p.Results);
% A special case for previously named parameter
if isfield(p.Unmatched, 'azimuth') && ...
    ismember(p.UsingDefaults, 'stimulusAzimuth')
  pars{3} = {p.azimuth};
end
% Repeat value for left and right stimuli (easier to do for all values)
pars = mapToCell(@(x)iff(isscalar(x), @()[x;x], x), pars);
[sigma, sf, az, c, ori] = deal(pars{:});
% al = pars.stimulusAltitude;
sigma = sigma(1); % Currently only one sigma value is supported
az = abs(az(1));

% Some hard-coded parameters
pixPerDeg = 3; % Pixels per visual degree
bgc = 127; % background colour
xExtent = 540; % Size of image in px
im = ones(70*pixPerDeg,xExtent*pixPerDeg)*bgc;
x = linspace(-xExtent/2, xExtent/2, size(im,2));
y = linspace(-35, 35, size(im,1));

gratSize = sigma*7*pixPerDeg;
gw = (gausswin(gratSize, 1/(sigma*pixPerDeg/gratSize*2))*gausswin(gratSize, 1/(sigma*pixPerDeg/gratSize*2))');
gw = gw./max(gw(:));

% sine wave
gratL = imrotate(repmat(sin((1:gratSize)/gratSize*2*pi*gratSize/pixPerDeg*sf(1)),gratSize,1).*gw*c(1),ori(1),'bilinear','crop');
gratR = imrotate(repmat(sin((1:gratSize)/gratSize*2*pi*gratSize/pixPerDeg*sf(2)),gratSize,1).*gw*c(2),ori(2),'bilinear','crop');

gratL = gratL*127+bgc;
gratR = gratR*127+bgc;

sy = round(size(im,1)/2);
insertIndsY = (1:gratSize)+sy-round(gratSize/2);

sx = round((-az+xExtent/2)*pixPerDeg);
insertInds = (1:gratSize)+sx-round(gratSize/2);
incl = insertInds>0&insertInds<size(im,2);
im(insertIndsY, insertInds(incl)) = gratL(:,incl);

sx = round((az+xExtent/2)*pixPerDeg);
insertInds = (1:gratSize)+sx-round(gratSize/2);
incl = insertInds>0&insertInds<size(im,2);
im(insertIndsY, insertInds(incl)) = gratR(:,incl);

