% vis.image test

% For each possible type of vis.image, make sure that:
% a) the image gets defined correctly
% b) the image can be assigned as a field to a StructRef 
%   (this mimics the assignment of a visual stimulus to the visual stimuli
%   subscriptable signal handler in an exp def)
% c) the image can have it's fields changed via assignment and/or signal 
%    updates
%    (this mimics using a parameter in an exp def to parametrize a
%    visual stimulus by changing a field(s) of that stimulus)
% d) the values posted to vector fields of the image element can be
%     assigned as either column or row vectors

% preconditions:
net = sig.Net;
t = net.origin('t');

%% Test 1: no image or window (returns an empty layer)

% a)
elem = vis.image(t);
assert(isobject(elem));
assert(isempty(elem.Node.CurrValue.sourceImage));

% b)
visStim = StructRef;
visStim.elem = elem;
assert(isobject(visStim));

%% Test 2: image as numeric array

% a)
sourceImageStruct = load(fullfile(fileparts(which('addSignalsPaths')),...
  '\tests\fixtures\data\img.mat'), 'img');
sourceImage = sourceImageStruct.img;
elem = vis.image(t, sourceImage);
assert(isobject(elem));

% b)
visStim = StructRef;
visStim.elem = elem;
assert(isobject(visStim));

% c)
pars = net.subscriptableOrigin('pars');
elem.colour = pars.elemColour;
elem.dims = pars.elemDims;
elem.show = true;
parsStruct = struct;
parsStruct.elemColour = [0 0 0];
parsStruct.elemDims = [20 20];

% can't use method call via dot notation on 'pars' b/c 'subsref' is overloaded for 'SubscriptableSignal' 
post(pars, parsStruct);

% assert elem's colour, dims, and layer values
assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]));
assert(isequal(elem.Node.CurrValue.dims.Node.CurrValue, [20 20]));
% all vectors in 'layers' struct should be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue.maxColour, [0 0 0 1]'));

% d)
% change parsStruct values to column vectors, and re-assert
parsStruct.elemColour = [0 0 0]';
parsStruct.elemDims = [20 20]';
post(pars, parsStruct);

assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]'));
assert(isequal(elem.Node.CurrValue.dims.Node.CurrValue, [20 20]'));
% all vectors in 'layers' struct should still be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue.maxColour, [0 0 0 1]'));

%% Test 3: image as standard image file

% a)
sourceImage = fullfile(fileparts(which('addSignalsPaths')),...
  '\tests\fixtures\data\img.jpg');
elem = vis.image(t, sourceImage);
assert(isobject(elem));

% b)
visStim = StructRef;
visStim.elem = elem;
assert(isobject(visStim));

% c)
pars = net.subscriptableOrigin('pars');
elem.colour = pars.elemColour;
elem.dims = pars.elemDims;
elem.show = true;
parsStruct = struct;
parsStruct.elemColour = [0 0 0];
parsStruct.elemDims = [20 20];

% can't use method call via dot notation on 'pars' b/c 'subsref' is overloaded for 'SubscriptableSignal' 
post(pars, parsStruct);

% assert elem's colour, dims, and layer values
assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]));
assert(isequal(elem.Node.CurrValue.dims.Node.CurrValue, [20 20]));
% all vectors in 'layers' struct should be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue.maxColour, [0 0 0 1]'));

% d)
% change parsStruct values to column vectors, and re-assert
parsStruct.elemColour = [0 0 0]';
parsStruct.elemDims = [20 20]';
post(pars, parsStruct);

assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]'));
assert(isequal(elem.Node.CurrValue.dims.Node.CurrValue, [20 20]'));
% all vectors in 'layers' struct should still be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue.maxColour, [0 0 0 1]'));
%% Test 4: gaussian window

% a)
sourceImage = 255*ones(250,250); window = 'gaussian';
elem = vis.image(t, sourceImage, window);
assert(isobject(elem));

% b)
visStim = StructRef;
visStim.elem = elem;
assert(isobject(visStim));

% c)
pars = net.subscriptableOrigin('pars');
elem.colour = pars.elemColour;
elem.dims = pars.elemDims;
elem.sigma = pars.elemSigma;
elem.show = true;
parsStruct = struct;
parsStruct.elemColour = [0 0 0];
parsStruct.elemDims = [20 20];
parsStruct.elemSigma = [10 10];

% can't use method call via dot notation on 'pars' b/c 'subsref' is overloaded for 'SubscriptableSignal' 
post(pars, parsStruct);

% assert elem's colour, dims, and layer values
assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]));
assert(isequal(elem.Node.CurrValue.dims.Node.CurrValue, [20 20]));
assert(isequal(elem.Node.CurrValue.sigma.Node.CurrValue, [10 10]));
% all vectors in 'layers' struct should be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue(2).maxColour, [0 0 0 1]'));
assert(strcmpi(elem.Node.CurrValue.layers.Node.CurrValue(1).textureId, 'gaussianStencil'));

% d)
% change parsStruct values to column vectors, and re-assert
parsStruct.elemColour = [0 0 0]';
parsStruct.elemDims = [20 20]';
post(pars, parsStruct);

assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]'));
assert(isequal(elem.Node.CurrValue.dims.Node.CurrValue, [20 20]'));
% all vectors in 'layers' struct should still be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue(2).maxColour, [0 0 0 1]'));
%% Test 5: impossible image

sourceImage = 'n/a';

try 
  vis.image(t,sourceImage);
catch ex
  assert(strcmpi(class(ex), 'MException'));
end

%% Test 6: impossible window

sourceImage = 255*ones(250,250);
window = 'n/a';

try 
  vis.image(t,sourceImage, window);
catch ex
  assert(strcmpi(ex.identifier, 'window:error'));
end