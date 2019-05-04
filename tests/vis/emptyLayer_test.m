% vis.emptyLayer test

%% Test 1: check layer creation

% a)
elem = vis.emptyLayer;
assert(isstruct(elem));

% b)
visStim = StructRef;
visStim.elem = elem;
assert(isobject(visStim));

%% Test 2: check layer replication

elem = vis.emptyLayer(3);
assert(isequal(numel(elem), 3));