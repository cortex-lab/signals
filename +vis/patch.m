function elem = patch(t, shape)
%VIS.PATCH Returns a Signals patch stimulus defining a texture of a shape
%  Produces a visual stimulus of a shape.
%
%  Inputs:
%    t - any signal with which to derive the network ID.  By convetion we
%      use the t signal
%    shape - char array defining what shape to show. Options are rectangle 
%      (default), circle and cross
%    
%  Outputs:
%    elem - a subscriptable signal containing paramter fields for the
%      stimulus along with the processed texture layer.  Any parameter may
%      be a signal.  
% 
%  Stimulus (elem) parameters:
%    azimuth - the position of the shape in the azimuth (position of the
%      centre pixel in visual degrees).  Default 0
%    altitude - the position of the shape in the altitude. Default 0
%    dims - the dimentions of the shape in visual degrees.  May be an array
%      of the form [width height] or a scalar if these dimentions are
%      equal.  Default [10 10]
%    orientation - the orientation of the shape in degrees. Default 0
%    colour - an array defining the intensity of the red, green and blue
%      channels respectively.  Values must be between 0 and 1.  Default [1
%      1 1]
%    show - a logical indicating whether or not the stimulus is visible.
%      Default false
%
%  See Also VIS.GRATING, VIS.CHECKER6, VIS.GRID, VIS.IMAGE

% Default shape is rectangle
if nargin < 2 || isempty(shape)
  shape = 'rectangle';
end

% Add a new subscriptable origin signal to the same network as the input
% signal, t, and use this to store the stimulus texture layer and
% parameters
elem = t.Node.Net.subscriptableOrigin('patch');
% Set some defaults for the stimulus
elem.azimuth = 0;
elem.altitude = 0;
elem.dims = [10 10]';
elem.orientation = 0;
elem.colour = [1 1 1]';
elem.show = false;
% Map the visual element signal through the below function 'makeLayer' and
% assign it to the layers field.  When any of the above parameters takes a
% new value, makeLayer is called, returning the texture layer.
% flattenStruct returns the same texture layer but with all fields
% containing signals replaced by their current value.  It is this field
% that is loaded by VIS.DRAW
elem.layers = elem.map(@makeLayer).flattenStruct();

  function layer = makeLayer(newelem)
    clear elem t; % eliminate references to unsed outer variables
    % Make a grating layer of the specified type
    switch lower(shape)
      case {'rectangle' 'rect' 'r'}
        [layer, img] = vis.rectLayer(...
          [newelem.azimuth; newelem.altitude],...
          newelem.dims, newelem.orientation);
        layer.textureId = 'square';
      case {'circle', 'circ'}
        [layer, img] = vis.circLayer(...
          [newelem.azimuth; newelem.altitude],...
          newelem.dims, newelem.orientation);
        layer.textureId = 'circle';
      case {'plus', 'cross'}
        [layer, img] = vis.crossLayer(...
          [newelem.azimuth; newelem.altitude],...
          newelem.dims, newelem.orientation);
        layer.textureId = 'cross';
      otherwise
        error('Invalid grating type ''%s''', shape);
    end
    layer.blending = 'source';
    % Set the layer colour according to the element's colour parameter,
    % adding a fourth, alpha, value
    layer.maxColour = [newelem.colour(:); 1];
    % Convert the texture image to the correct format: a column vector of
    % RGBA values between 0 and 255, saving the image size in the rabaSize
    % field
    [layer.rgba, layer.rgbaSize] = vis.rgba(1, img);
    layer.show = newelem.show;
  end

end