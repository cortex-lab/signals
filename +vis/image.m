function elem = image(t, sourceImage, window)
% VIS.IMAGE Returns a visual element for image presentation in Signals
%  Produces a visual element for parameterizing the presentation of an
%  image.
%
%  Inputs:
%    't' - The "time" signal. Used to obtain the Signals network ID.
%      (Could be any signal within the network - 't' is chosen by
%      convention).
%    'sourceImage' - Either an image or path to an image.
%    'window' - A char array defining the type of windowing applied.
%      Options are 'none' (default) or 'gaussian'.
%
%  Outputs:
%    'elem' - a subscriptable signal containing fields which parametrize
%      the stimulus, and a field containing the processed texture layer. 
%      Any of the fields may be a signal.
%
%  Stimulus parameters (fields belonging to 'elem'):
%    'grating' - see above
%    'window' - see above
%    'azimuth' - the position of the shape in the azimuth (position of the
%      centre pixel in visual degrees).  Default 0
%    'altitude' - the position of the shape in the altitude. Default 0
%    'sigma' - if window is Gaussian, the size of the window in visual
%      degrees.  Must be an array of the form [width height].
%      Default [10 10]
%    'phase' - the phase of the grating in visual degrees.  Default 0
%    'spatialFreq' - the spatial frequency of the grating in cycles per
%      visual degree.  Default 1/15
%    'orientation' - the orientation of the grating in degrees. Default 0
%    'colour' - an array defining the intensity of the red, green and blue
%      channels respectively.  Values must be between 0 and 1.
%      Default [1 1 1]
%    'contrast' - the normalized contrast of the image (between 0 and 1).
%      Default 1
%    'show' - a logical indicating whether or not the stimulus is visible.
%      Default false
%
%  See Also VIS.EMPTYLAYER, VIS.PATCH, VIS.GRATING, VIS.CHECKER6, VIS.GRID,
%
%  TODO Add contrast parameter

% Define our default inputs
if nargin < 2
  sourceImage = [];
else
  % If the image is a char array, assume it is a path and attempt to load
  % the image
  if isa(sourceImage, 'char')
    sourceImage = imread(sourceImage);
  end
end
if nargin < 3 || isempty(window)
  window = 'none';
end

% Add a new subscriptable origin signal to the same network as the input
% signal, 't', and use this to store the stimulus texture layer and
% parameters
elem = t.Node.Net.subscriptableOrigin('image');
elem.azimuth = 0;
elem.altitude = 0;
elem.dims = [50,50]';
elem.orientation = 0;
elem.sourceImage = sourceImage;
elem.colour = [1 1 1]';
elem.rescale = false;
elem.show = false;
elem.isPeriodic = false;
elem.window = window;
elem.sigma = [5,5]';

% Map the visual element signal through the below function 'makeLayer' and
% assign it to the 'layers' field.  When any of the above parameters takes
% a new value, 'makeLayer' is called, returning the texture layer.
% 'flattenStruct' returns the same texture layer but with all fields
% containing signals replaced by their current value. The 'layers' field
% is loaded by VIS.DRAW
elem.layers = elem.map(@makeLayers).flattenStruct();

  function layers = makeLayers(newelem)
    clear elem t; % eliminate references to unused outer variables
    % make an image layer
    imgLayer = vis.emptyLayer();
    % If 'sourceImage' field is empty, return an empty layer
    if isempty(newelem.sourceImage)
      layers = imgLayer;
      return
    end
    imgLayer.texOffset = [newelem.azimuth, newelem.altitude];
    imgLayer.texAngle = newelem.orientation;
    imgLayer.size = newelem.dims;
    imgLayer.isPeriodic = newelem.isPeriodic;
    imgLayer.textureId = 'image';
    imgLayer.interpolation = 'linear';
    imgLayer.maxColour = [newelem.colour(:); 1];
    
    % Convert the texture image to the correct format - a column vector of
    % RGBA values between 0 and 255. Output the image size to the
    % 'rgbaSize' field
    if isobject(newelem.sourceImage)
      if newelem.rescale
        imgLayer.rgba = map(newelem.sourceImage,...
          @(img)vis.rgbaFromUint8(rescale(img),1));
      else
        imgLayer.rgba = map(newelem.sourceImage, @(img)vis.rgba(img,1));
      end
      imgLayer.rgbaSize = map(newelem.sourceImage,...
        @(img)[size(img,2), size(img,1)]);
    else
      if newelem.rescale
        [imgLayer.rgba, imgLayer.rgbaSize] = ...
          vis.rgbaFromUint8(rescale(newelem.sourceImage),1);
      else
        [imgLayer.rgba, imgLayer.rgbaSize] = ...
          vis.rgba(newelem.sourceImage,1);
      end
    end
    
    imgLayer.show = newelem.show;
    
    % make a stencil layer using a window of the specified type
    if ~strcmpi(newelem.window, 'none')
      switch lower(newelem.window)
        case {'gaussian' 'gauss'}
          [winLayer, winImg] = vis.gaussianLayer(...
            [newelem.azimuth; newelem.altitude], newelem.sigma);
          winLayer.textureId = 'gaussianStencil';
        otherwise
          error('Invalid window type ''%s''', newelem.window);
      end
      [winLayer.rgba, winLayer.rgbaSize] = vis.rgba(0, winImg);
      winLayer.blending = 'none';
      winLayer.colourMask = [false false false true];
      winLayer.show = newelem.show;
    else % no window
      winLayer = [];
    end
    layers = [winLayer, imgLayer];
  end
  function img = rescale(img)
    img = max(img,-1); img = min(img, 1);
    img = uint8(img*128+128);
  end
end