% vis.grid test

% preconditions:
net = sig.Net;
t = net.origin('t');

% Make sure:
% a) the grid gets defined correctly
% b) the grid can be assigned as a field to a StructRef 
%    (this mimics the assignment of a visual stimulus to the visual stimuli
%    subscriptable signal handler in an exp def)
% c) the grid can have it's fields changed via assignment and/or signal 
%    updates
%    (this mimics using a parameter in an exp def to parametrize a
%    visual stimulus by changing a field(s) of that stimulus)
% d) the values posted to vector fields of the grid can be
%    assigned as either column or row vectors

% @todo add test for if/when 'azimuths' and 'altitudes' can be set as
% signals

%% Test 1: check layer creation

% a)
elem = vis.grid(t);
assert(isobject(elem));

% b)
visStim = StructRef;
visStim.elem = elem;
assert(isobject(visStim));

% c)
pars = net.subscriptableOrigin('pars');
elem.colour = pars.elemColour;
cols = [-180:45:180];
rows = [-90:45:90];
elem.azimuths = cols; %#ok<*NBRAK>
elem.altitudes = rows;
parsStruct = struct;
parsStruct.elemColour = [0 0 0];
numLayers = numel(cols) + numel(rows);

% can't use method call via dot notation on 'pars' b/c 'subsref' is overloaded for 'SubscriptableSignal' 
post(pars, parsStruct);

% assert elem's colour, sigma, and layer values
assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]));
% all vectors in 'layers' struct should be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue.maxColour, [0 0 0 1]'));
% number of layers in the element should match expected
assert(isequal(numel(elem.node.CurrValue.layers.Node.CurrValue), numLayers));

% d)
% change parsStruct values to column vectors, and re-assert
parsStruct.elemColour = [0 0 0]';
post(pars, parsStruct);

assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]'));
% all vectors in 'layers' struct should still be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue.maxColour, [0 0 0 1]'));