% vis.gaussianLayer test

% preconditions
net = sig.Net;
load([fileparts(which('addSignalsPaths')) '\tests\fixtures\data\gauss.mat'], 'gauss');

%% Test one: standard inputs
pos = [10 5];
sigma = [5 5];
[layer, img] = vis.gaussianLayer(pos, sigma);
% Verify layer properties correctly set
assert(strcmp(layer.interpolation, 'linear'), 'interpolation incorrect');
assert(all(layer.texOffset == pos), 'texOffset incorrect');
assert(layer.texAngle == 0, 'texAngle incorrect');
assert(all(layer.size == 36), 'size incorrect');
assert(~layer.isPeriodic, 'isPeriodic set to true');
% Verify image is correct
assert(isa(img, 'single'), 'incorrect type');
assert(isequal(img, gauss), 'img incorrect');

%% Test two
pos = net.origin('position');
sigma = net.origin('sigma');

[layer, img] = vis.gaussianLayer(pos, sigma);
pos.post([10, 5]);
sigma.post([5, 5]);

% Verify layer properties correctly set
assert(all(layer.texOffset.Node.CurrValue == pos.Node.CurrValue), ...
  'texOffset incorrect');
assert(all(layer.size.Node.CurrValue == 36), 'size incorrect');
% Verify image is correct
assert(isa(img, 'single'), 'incorrect type');
assert(isequal(img, gauss), 'img incorrect');