function layer = emptyLayer(n)
%VIS.EMPTYLAYER Template texture layer for rendering in Signals
%  Returns a struct of paramters and their defaults used by VIS.DRAW to
%  load a visual stimulus layer.  If n > 1 a non-scalar struct is returned
%  of length n (default 1).
%
%  TODO Document viewAngle, texAngle and pos
%  @body There is currently no information on how these three parameters
%  are used by the viewing model.  For example, what is the practical
%  difference between `texOffset` and `pos`, or `viewAngle` and `texAngle`?
%
%  See also VIS.DRAW, VIS.RGBA

% Create an empty structure
layer = struct;
% SHOW a logical indicating whether or not the stimulus is visible
layer.show = false;
% TEXTUREID a char array used by VIS.DRAW to identify the texture layer.
% Layers with unique texture data (i.e. the data stored in rgba) must have
% unique IDs in order to be loaded into the buffer seperately.  Preceeding
% the ID with '~' indicates that it is a dynamic texture to be loaded anew
% each time. Dynamic textures are those where the underlying image array
% changes.
layer.textureId = [];
% POS 
layer.pos = [0 0]';
% SIZE array of the form [azimuth altitude] defining the size of the
% texture in visual degrees
layer.size = [0 0]';
% VIEWANGLE The view angle in degrees 
layer.viewAngle = 0;
% TEXANGLE the texture angle in degrees
layer.texAngle = 0;
% TEXOFFSET an array of the form [azimuth altitude] indicating the texture
% offset from the centre of the viewer's visual field in visual degrees
layer.texOffset = [0 0]';
% ISPERIODIC logical - when true the texture is replicated across the
% entire visual space
layer.isPeriodic = true;
% BLENDING char array defining the type of blending used.  
% Options:
%  'none' (/ ''), 
%  'source' (/ 'src'), 
%  'destination' (/ 'dst'), 
%  '1-source' (/'1-src')
layer.blending = 'source';
% MINCOLOUR & MAXCOLOUR arrays of the form [R G B A] indicating the min
% (max) intensity of the red, green and blue channels, along with the amout
% of opacity (alpha).  Values must be between 0 and 1.
layer.minColour = [0 0 0 0]';
layer.maxColour = [1 1 1 1]';
% COLOURMASK logical array indicating whether the red, green, blue and
% alpha channels may be written to the frame buffer.  When any of these
% channels are set to false no change is made to that component of any
% pixel in any of the color buffers, regardless of any changes to the
% texture image
layer.colourMask = [true true true true]';
% INTERPOLATION char array indicating the type of interpolation applied.
% Options:
%  'nearest' - Nearest neighbour interpolation
%  'linear' - linear interpolation
layer.interpolation = 'linear';
% RGBA Column array of uint8 RGBA values for each pixel (left to right, top
% to bottom) in the texture image. The values must be between 0 and 255.
% For example take a matrix.  See also VIS.RGBA
layer.rgba = [];
% RGBASIZE array of the form [m n] where m and n are the sizes of the first
% two dimentions of the texture image
layer.rgbaSize = [0 0]';

% Replicate the layer n times
if nargin > 0 
  layer = repmat(layer, 1, n);
end

end
