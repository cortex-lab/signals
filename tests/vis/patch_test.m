% vis.patch test

% For each possible type of vis.patch, make sure that:
% a) the patch gets defined correctly
% b) the patch can be assigned as a field to a StructRef 
%   (this mimics the assignment of a visual stimulus to the visual stimuli
%   subscriptable signal handler in an exp def)
% c) the patch can have it's fields changed via assignment and/or signal 
%    updates
%    (this mimics using a parameter in an exp def to parametrize a
%    visual stimulus by changing a field(s) of that stimulus)
% d) the values posted to vector fields of the patch can be
%     assigned as either column or row vectors

% preconditions:
net = sig.Net;
t = net.origin('t');
mess = onCleanup(@() delete(net)); % Delete network

%% Test 1: no specified shape

% a)
elem = vis.patch(t);
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

%% Test 2: rectangle

% a)
shape = 'rectangle';
elem = vis.patch(t, shape);
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

%% Test 3: circle

% a)
shape = 'circle';
elem = vis.patch(t, shape);
assert(isobject(elem));

% b)
visStim = StructRef;
visStim.elem = elem;
assert(isobject(visStim));

% c)
pars = net.subscriptableOrigin('pars');
elem.colour = pars.elemColour;
elem.show = true;
% @todo if/when 'dims' for 'circle' is able to be assigned a signal, 
% create a test for this
% elem.dims = pars.elemDims; 
parsStruct = struct;
parsStruct.elemColour = [0 0 0];

% can't use method call via dot notation on 'pars' b/c 'subsref' is overloaded for 'SubscriptableSignal' 
post(pars, parsStruct);

% assert elem's colour, dims, and layer values
assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]));
% all vectors in 'layers' struct should be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue.maxColour, [0 0 0 1]'));

% d)
% change parsStruct values to column vectors, and re-assert
parsStruct.elemColour = [0 0 0]';
post(pars, parsStruct);

assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]'));
% all vectors in 'layers' struct should still be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue.maxColour, [0 0 0 1]'));

%% Test 4: cross

% a)
shape = 'cross';
elem = vis.patch(t, shape);
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

%% Test 5: impossible shape

shape = 'n/a';

try 
  vis.patch(t,shape)
catch ex
  assert(strcmpi(ex.identifier, 'shape:error'));
end