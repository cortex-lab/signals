% vis.grating test

% For each possible type of vis.grating, make sure that:
% a) the grating gets defined correctly
% b) the grating can be assigned as a field to a StructRef 
%   (this mimics the assignment of a visual stimulus to the visual stimuli
%   subscriptable signal handler in an exp def)
% c) the grating can have it's fields changed via assignment and/or signal 
%    updates
%    (this mimics using a parameter in an exp def to parametrize a
%    visual stimulus by changing a field(s) of that stimulus)
% d) the values posted to vector fields of the grating can be
%     assigned as either column or row vectors

% preconditions:
net = sig.Net;
t = net.origin('t');
ex = struct('identifier', '', 'message', '');
mess = onCleanup(@() delete(net)); % Delete network

%% Test 1: no window

% Test defaults
elem = vis.grating(t);
assert(strcmp(elem.Name, 'gabor'), 'Unexpected element name')
assert(strcmp(elem.Node.CurrValue.grating, 'sinusoid'), 'Unexpected grating type default')
assert(strcmp(elem.Node.CurrValue.window, 'gaussian'), 'Unexpected window default')
assert(all(structfun(@isempty, elem.Node.CurrValue) == false), 'Undefined default parameters')

% a)
grating = 'sinusoid';
window = 'none';
elem = vis.grating(t, grating, window);
assert(isobject(elem));

% b)
visStim = StructRef;
visStim.elem = elem;
assert(isobject(visStim));

% c)
pars = net.subscriptableOrigin('pars');
elem.colour = pars.elemColour;
elem.sigma = pars.elemSigma;
elem.show = true;
parsStruct = struct;
parsStruct.elemColour = [0 0 0];
parsStruct.elemSigma = [20 20];

% can't use method call via dot notation on 'pars' b/c 'subsref' is overloaded for 'SubscriptableSignal' 
post(pars, parsStruct);

% assert elem's colour, sigma, and layer values
assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]))
assert(isequal(elem.Node.CurrValue.sigma.Node.CurrValue, [20 20]))
% all vectors in 'layers' struct should be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue.maxColour, [0 0 0 1]'))

% d)
% change parsStruct values to column vectors, and re-assert
parsStruct.elemColour = [0 0 0]';
parsStruct.elemSigma = [20 20]';
post(pars, parsStruct);

assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]'))
assert(isequal(elem.Node.CurrValue.sigma.Node.CurrValue, [20 20]'))
% all vectors in 'layers' struct should still be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue.maxColour, [0 0 0 1]'))

%% Test 2: sinusoid grating

% a)
grating = 'sinusoid';
elem = vis.grating(t, grating);
assert(isobject(elem));

% b)
visStim = StructRef;
visStim.elem = elem;
assert(isobject(visStim));

% c)
pars = net.subscriptableOrigin('pars');
elem.colour = pars.elemColour;
elem.sigma = pars.elemSigma;
elem.show = true;
parsStruct = struct;
parsStruct.elemColour = [0 0 0];
parsStruct.elemSigma = [20 20];

% can't use method call via dot notation on 'pars' b/c 'subsref' is overloaded for 'SubscriptableSignal' 
post(pars, parsStruct);

% assert elem's colour, sigma, and layer values
assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]))
assert(isequal(elem.Node.CurrValue.sigma.Node.CurrValue, [20 20]))
% all vectors in 'layers' struct should be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue(2).maxColour, [0 0 0 1]'))

% d)
% change parsStruct values to column vectors, and re-assert
parsStruct.elemColour = [0 0 0]';
parsStruct.elemSigma = [20 20]';
post(pars, parsStruct);

assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]'))
assert(isequal(elem.Node.CurrValue.sigma.Node.CurrValue, [20 20]'))
% all vectors in 'layers' struct should still be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue(2).maxColour, [0 0 0 1]'))

%% Test 3: squarewave grating

% a)
grating = 'squarewave';
elem = vis.grating(t, grating);
assert(isobject(elem))

% b)
visStim = StructRef;
visStim.elem = elem;
assert(isobject(visStim))

% c)
pars = net.subscriptableOrigin('pars');
elem.colour = pars.elemColour;
elem.sigma = pars.elemSigma;
elem.show = true;
parsStruct = struct;
parsStruct.elemColour = [0 0 0];
parsStruct.elemSigma = [20 20];

% can't use method call via dot notation on 'pars' b/c 'subsref' is overloaded for 'SubscriptableSignal' 
post(pars, parsStruct);

% assert elem's colour, sigma, and layer values
assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]))
assert(isequal(elem.Node.CurrValue.sigma.Node.CurrValue, [20 20]))
% all vectors in 'layers' struct should be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue(2).maxColour, [0 0 0 1]'))

% d)
% change parsStruct values to column vectors, and re-assert
parsStruct.elemColour = [0 0 0]';
parsStruct.elemSigma = [20 20]';
post(pars, parsStruct);

assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]'))
assert(isequal(elem.Node.CurrValue.sigma.Node.CurrValue, [20 20]'))
% all vectors in 'layers' struct should still be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue(2).maxColour, [0 0 0 1]'))

%% Test 4: gaussian window

% a)
grating = 'sinusoid'; window = 'gaussian';
elem = vis.grating(t, grating, window);
assert(isobject(elem))

% b)
visStim = StructRef;
visStim.elem = elem;
assert(isobject(visStim))

% c)
pars = net.subscriptableOrigin('pars');
elem.colour = pars.elemColour;
elem.sigma = pars.elemSigma;
elem.show = true;
parsStruct = struct;
parsStruct.elemColour = [0 0 0];
parsStruct.elemSigma = [20 20];

% can't use method call via dot notation on 'pars' b/c 'subsref' is overloaded for 'SubscriptableSignal' 
post(pars, parsStruct);

% assert elem's colour, sigma, and layer values
assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]))
assert(isequal(elem.Node.CurrValue.sigma.Node.CurrValue, [20 20]))
% all vectors in 'layers' struct should be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue(2).maxColour, [0 0 0 1]'))

% d)
% change parsStruct values to column vectors, and re-assert
parsStruct.elemColour = [0 0 0]';
parsStruct.elemSigma = [20 20]';
post(pars, parsStruct);

assert(isequal(elem.Node.CurrValue.colour.Node.CurrValue, [0 0 0]'))
assert(isequal(elem.Node.CurrValue.sigma.Node.CurrValue, [20 20]'))
% all vectors in 'layers' struct should still be column vectors
assert(isequal(elem.Node.CurrValue.layers.Node.CurrValue(2).maxColour, [0 0 0 1]'))

%% Test 5: impossible grating

grating = 'n/a';

try 
  vis.grating(t, grating);
catch ex
end
assert(strcmpi(ex.identifier, 'grating:error'))

%% Test 6: impossible window

grating = 'sinusoid';
window = 'n/a';

try 
  vis.grating(t, grating, window);
catch ex
end
assert(strcmpi(ex.identifier, 'window:error'))
