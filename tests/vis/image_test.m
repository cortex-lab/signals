% preconditions
net = sig.Net;
t = net.origin('testNode');
testImages = load('imdemos.mat');

%% Test 1: Rescale MATLAB double array
img = double(testImages.circles);
elem = vis.image(t, img);
layer = elem.Node.CurrValue.layers.Node.CurrValue;

assert(isequal(img, elem.Node.CurrValue.sourceImage), ...
  'Source image incorrectly assigned')
assert(strcmp(elem.Node.CurrValue.window, 'none'), 'Unexpected window value')
assert(layer.textureId(1) ~= '~', 'Texture should be static')
assert(isequal(layer.rgbaSize, size(img)), 'Size incorrect')
assert(isa(layer.rgba, 'uint8'), 'incorrect data type')
assert(isequal(size(layer.rgba), [prod([size(img) 4]) 1]), 'incorrect size')

%% Test 2: Source image defined as a path
img = imread('cell.tif');
elem = vis.image(t, 'cell.tif');
layer = elem.Node.CurrValue.layers.Node.CurrValue;

assert(isequal(img, elem.Node.CurrValue.sourceImage), ...
  'Source image incorrectly assigned')
assert(layer.textureId(1) ~= '~', 'Texture should be static')
assert(isequal(layer.rgbaSize, fliplr(size(img))), 'Size incorrect')
assert(isa(layer.rgba, 'uint8'), 'incorrect data type')
assert(isequal(size(layer.rgba), [prod([size(img) 4]) 1]), 'incorrect size')

%% Test 3: Source image as Signal
img = net.origin('image');
elem = vis.image(t, img);
img.post(testImages.pepper)
layer = elem.Node.CurrValue.layers.Node.CurrValue;

assert(isequal(img, elem.Node.CurrValue.sourceImage), ...
  'Source image incorrectly assigned')
assert(layer.textureId(1) == '~', 'Texture should be dynamic')
assert(isequal(layer.rgbaSize, size(img.Node.CurrValue)), 'Size incorrect')
assert(isa(layer.rgba, 'uint8'), 'incorrect data type')
assert(isequal(size(layer.rgba), [prod([size(img.Node.CurrValue) 4]) 1]), 'incorrect size')

%% Test 4: Check alpha loaded correctly
% Loads an RGBA file where sourceImage is an m by n by 3 array
pth = fullfile(matlabroot,'toolbox','images','icons','ruler_24.png');
[img,~,alpha] = imread(pth);
sz = [size(img,1) size(img,2)];
elem = vis.image(t, pth);
layer = elem.Node.CurrValue.layers.Node.CurrValue;

assert(isequal(img, elem.Node.CurrValue.sourceImage), ...
  'Source image incorrectly assigned')
assert(layer.textureId(1) ~= '~', 'Texture should be static')
assert(isequal(layer.rgbaSize, sz), 'Size incorrect')
assert(isa(layer.rgba, 'uint8'), 'incorrect data type')
assert(isequal(size(layer.rgba), [prod([sz 4]) 1]), 'incorrect size')
test_alpha = reshape(layer.rgba(4:4:length(layer.rgba)), size(alpha));
assert(isequal(alpha, test_alpha), 'alpha incorrectly set')

%% Test 5: Test windowing & position parameters
pars = num2cell(rand(1,3));
dims = randi(100,1,2);
elem = vis.image(t, 'cell.tif');
elem.window = 'gauss';
[elem.azimuth, elem.altitude, elem.orientation] = pars{:};
elem.dims = dims;
l = elem.Node.CurrValue.layers.Node.CurrValue;

% Check gaussian stencil
assert(numel(l)==2, 'unexpected number of texture layers')
assert(strcmp(l(1).textureId, 'gaussianStencil'), 'unexpected layer order')
assert(isequal(l(1).texOffset, [pars{1:2}]'), 'unexpected stencil offset') % TODO shape of size and texOffset arrays inconsistent
% Check parameters were set correctly
correct = isequal([l(2).texOffset l(2).texAngle l(2).size], [pars{:} dims]);
assert(correct, 'inconsistent layer parameters')

%% Test 6: Test texture id names
clear image
elem1 = vis.image(t, 'cell.tif');
elem2 = vis.image(t, magic(6));
elem3 = vis.image(t);
elem3.sourceImage = randi(240);
elem4 = vis.image(t, t.map(@(i)randi(floor(i))));

names = cellfun(@(n)n.Node.CurrValue.layers.Node.CurrValue.textureId, ...
  {elem1, elem2, elem3, elem4}, 'UniformOutput', false);
expected = {'cell', 'image1', 'image2', '~testNode.map(@(i)randi(floor(i)))'};
assert(isequal(names, expected), 'unexpected texture ids')
