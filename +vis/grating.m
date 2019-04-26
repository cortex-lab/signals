function elem = grating(t, grating, window)
%VIS.GRATING Returns a Signals grating stimulus defining a grating texture
%  Produces a grating element that is either sinusoidal or square-wave, and
%  may be windowed by a Gaussian stencil, producing a Gabor patch
%
%  Inputs:
%    t - The 'time' signal. Used to obtain the Signals network ID.
%      (Could be any signal within the network - 't' is chosen by
%      convention).
%    grating - char array defining the nature of the grating. Options are
%      'sinusoid' (default) or 'squarewave'.
%    window - char array defining the type of windowing applied.  Options
%      are 'none' (default) or 'gaussian'.
%    
%  Outputs:
%    elem - a subscriptable signal containing paramter fields for the
%      stimulus along with the processed texture layers.  Any parameter may
%      be a signal.  
% 
%  Stimulus (elem) parameters:
%    grating - see above
%    window - see above
%    azimuth - the position of the shape in the azimuth (position of the
%      centre pixel in visual degrees).  Default 0
%    altitude - the position of the shape in the altitude. Default 0
%    sigma - if window is Gaussian, the size of the window in visual 
%      degrees.  Must be an array of the form [width height].  
%      Default [10 10]
%    phase - the phase of the grating in visual degrees.  Default 0
%    spatialFreq - the spatial frequency of the grating in cycles per
%      visual degree.  Default 1/15
%    orientation - the orientation of the grating in degrees. Default 0
%    colour - an array defining the intensity of the red, green and blue
%      channels respectively.  Values must be between 0 and 1.  Default [1
%      1 1]
%    contrast - the normalized contrast of the grating (between 0 and 1).  
%      Default 1
%    show - a logical indicating whether or not the stimulus is visible.
%      Default false
%
%  See Also VIS.GRATING, VIS.CHECKER6, VIS.GRID, VIS.IMAGE

% Define our default inputs
if nargin < 3 || isempty(window)
  window = 'gaussian';
end
if nargin < 2 || isempty(grating)
  grating = 'sinusoid';
end

% Add a new subscriptable origin signal to the same network as the input
% signal, t, and use this to store the stimulus texture layer and
% parameters
elem = t.Node.Net.subscriptableOrigin('gabor');
% Set some defaults for the stimulus
elem.grating = grating;
elem.window = window;
elem.azimuth = 0;
elem.altitude = 0;
elem.sigma = [10 10];
elem.spatialFreq = 1/15;
elem.phase = 0;
elem.orientation = 0;
elem.colour = [1 1 1];
elem.contrast = 1;
elem.show = false;

% Map the visual element signal through the below function 'makeLayer' and
% assign it to the layers field.  When any of the above parameters takes a
% new value, makeLayer is called, returning the texture layer.
% flattenStruct returns the same texture layer but with all fields
% containing signals replaced by their current value.  It is this field
% that is loaded by VIS.DRAW
elem.layers = elem.map(@makeLayers).flattenStruct();
end

function layers = makeLayers(newelem)
%% make a grating layer of the specified type
switch lower(newelem.grating)
  case {'sinusoid' 'sine' 'sin'}
    [gratingLayer, gratingImg] = vis.sinusoidLayer(newelem.azimuth,...
      newelem.spatialFreq, newelem.phase, newelem.orientation);
    gratingLayer.textureId = 'sinusoidGrating';
  case {'squarewave' 'square' 'sq'}
    [gratingLayer, gratingImg] = vis.squareWaveLayer(newelem.azimuth,...
      newelem.spatialFreq, newelem.phase, newelem.orientation);
    gratingLayer.textureId = 'squareWaveGrating';
  otherwise
    error('Invalid grating type ''%s''', grating);
end
% Convert the texture image to the correct format: a column vector of
% RGBA values between 0 and 255, saving the image size in the rabaSize
% field
[gratingLayer.rgba, gratingLayer.rgbaSize] = vis.rgba(gratingImg, 1);
gratingLayer.blending = 'destination';
% Scale the min and max colours in each channel by the contrast
l = 0.5 - 0.5*newelem.contrast;
h = 0.5 + 0.5*newelem.contrast;
gratingLayer.minColour = l.*[newelem.colour 0];
gratingLayer.maxColour = h.*[newelem.colour 1];
gratingLayer.show = newelem.show;

%% make a stencil layer using a window of the specified type
if ~strcmpi(newelem.window, 'none')
  switch lower(newelem.window)
    case {'gaussian' 'gauss'}
      [winLayer, winImg] = vis.gaussianLayer(...
        [newelem.azimuth; newelem.altitude], newelem.sigma);
      winLayer.textureId = 'gaussianStencil';
    otherwise
      error('Invalid window type ''%s''', window);
  end
  [winLayer.rgba, winLayer.rgbaSize] = vis.rgba(0, winImg);
  winLayer.blending = 'none';
  % Hold the RGBA values fixed at 0 as we only care about the alpha channel
  winLayer.colourMask = [false false false true];
  winLayer.show = newelem.show;
else % no window
  winLayer = [];
end

% The window layer is rendered first like a stencil
layers = [winLayer, gratingLayer];
end
