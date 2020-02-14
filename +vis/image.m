function elem = image(t, sourceImage, alpha)
% VIS.IMAGE Returns a visual element for image presentation in Signals
%  Produces a visual element for parameterizing the presentation of an
%  image.
%
%  Inputs:
%    't' - The "time" signal. Used to obtain the Signals network ID.
%      (Could be any signal within the network - 't' is chosen by
%      convention).
%    'sourceImage' - Either a standard image file, or path to a '.mat' file
%      containing an image represented as a numeric array, or a signal 
%      whose value is an image represtented as a numeric array.
%    'alpha' - the alpha value(s) for the image (optional).  Can be a
%      single value or array the size of 'sourceImage.'  If no alpha value
%      is provided and sourceImage is a char the image will be opaque.
%      This input overrides the source image's values if it has any.
%
%  Outputs:
%    'elem' - a subscriptable signal containing fields which parametrize
%      the stimulus, and a field containing the processed texture layer. 
%      Any of the fields may be a signal.
%
%  Stimulus parameters:
%    'sourceImage' - see above
%    'window' - If 'gaussian' or 'gauss', a Gaussian window is applied over
%      the image.  Default is 'none'.
%    'sigma' - the size of the gaussian window in visual degrees [w h].
%      Default [5 5].
%    'azimuth' - the azimuth of the image (position of the centre pixel in 
%      visual degrees).  Default 0
%    'altitude' - the altitude of the image (position of the centre pixel 
%      in visual degrees). Default 0
%    'dims' - the dimensions of the shape in visual degrees. May be an
%      array of the form [width height] or a scalar if these dimensions are
%      equal. Default [10 10]
%    'orientation' - the orientation of the image in degrees. Default 0
%    'repeat' - a logical indicating whether or not to repeat the image
%      over the entire visual field. Default false
%    'show' - a logical indicating whether or not the stimulus is visible.
%      Default false
%
%  NB: If loading multiple visual elements with different image paths,
%  ensure that the images themselves have unique filenames.
%
%  See Also VIS.EMPTYLAYER, VIS.PATCH, VIS.GRATING, VIS.CHECKER6, VIS.GRID, IMREAD
%  
%  TODO Add contrast parameter
%  @body Add parameter to set overall contrast of the image, effectively
%  scaling it?  Would need to know the range of the source image...
%
%  TODO Add colour parameter
%  @body Add parameter to set the intensity of each channel. How would this
%  work for none-greyscale source images?

% Add a new subscriptable origin signal to the same network as the input
% signal, t, and use this to store the stimulus texture layer and
% parameters
elem = t.Node.Net.subscriptableOrigin('image');
elem.azimuth = 0;
elem.altitude = 0;
elem.dims = [50,50]';
elem.orientation = 0;
elem.repeat = false;
elem.sourceImage = [];
elem.alpha = 1;
elem.show = false;
elem.window = 'none';
elem.sigma = [5,5]';

% Map the visual element signal through the below function 'makeLayer' and
% assign it to the layers field.  When any of the above parameters takes a
% new value, makeLayer is called, returning the texture layer.
% flattenStruct returns the same texture layer but with all fields
% containing signals replaced by their current value.  It is this field
% that is loaded by VIS.DRAW
elem.layers = elem.map(@makeLayers).flattenStruct();

% Deal with texture naming
persistent imageNum
name = sprintf('image%i',imageNum);
% If source image is given as an input, update the visual element
if nargin > 1
  % If the image is a char array, assume it is a path and attempt to load
  % the image.  If there's a transparency layer, use it.
  if isa(sourceImage, 'char')
    [~,filename,~] = fileparts(sourceImage);
    name = sprintf('%s',filename); 
    [elem.sourceImage, ~, srcAlpha] = imread(sourceImage);
    if ~isempty(srcAlpha); elem.alpha = srcAlpha; end
  elseif isa(sourceImage, 'sig.Signal') && ~isa(sourceImage, 'sig.VoidSignal')
    name = sourceImage.Name;
    elem.sourceImage = sourceImage;
  else % Otherwise it must be an image
    elem.sourceImage = sourceImage;
  end
end
% If input alpha is none-empty, overwrite whatever was returned by imread.
if nargin > 2 && ~isempty(alpha); elem.alpha = alpha; end
imageNum = iff(isempty(imageNum), 1, imageNum + 1);
elem.Name = name;

  function layers = makeLayers(newelem)
    %% make an image layer
    imgLayer = vis.emptyLayer();
    % If sourceImage field is empty, return an empty layer
    if isempty(newelem.sourceImage)
      layers = imgLayer;
      return
    end
    imgLayer.texOffset = [newelem.azimuth, newelem.altitude];
    imgLayer.texAngle = newelem.orientation;
    imgLayer.size = newelem.dims;
    imgLayer.isPeriodic = newelem.repeat;
    imgLayer.interpolation = 'linear';
    
    if isobject(newelem.sourceImage)
      % FIXME Make vis.rgba a Signal method or define new image subclass? 
      imgLayer.textureId = ['~' name];
      imgLayer.rgba = map(newelem.sourceImage, @(img)vis.rgba(img,1));
      imgLayer.rgbaSize = map(newelem.sourceImage,...
        @(img)[size(img,2), size(img,1)]);
    else
      imgLayer.textureId = name;
      [imgLayer.rgba, imgLayer.rgbaSize] = ...
        vis.rgba(newelem.sourceImage, newelem.alpha);
    end
    imgLayer.show = newelem.show;
    
    %% make a stencil layer using a window of the specified type
    if ~strcmpi(newelem.window, 'none')
      switch lower(newelem.window)
        case {'gaussian' 'gauss'}
          [winLayer, winImg] = vis.gaussianLayer(...
            [newelem.azimuth; newelem.altitude], newelem.sigma);
          winLayer.textureId = 'gaussianStencil';
        otherwise
          error('window:error', 'Invalid window type ''%s''', newelem.window);
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
end