% vis.rectLayer test

% preconditions
net = sig.Net;

%% Test one: standard inputs
pos = [10 5];
dims = [50 50];
ori = 12;
[layer, img] = vis.rectLayer(pos, dims, ori);
% Verify layer properties correctly set
assert(strcmp(layer.interpolation, 'nearest'), 'interpolation incorrect');
assert(all(layer.texOffset == pos), 'texOffset incorrect');
assert(layer.texAngle == ori, 'texAngle incorrect');
assert(all(layer.size == 150), 'size incorrect');
assert(~layer.isPeriodic, 'isPeriodic set to true');
% Verify image is correct
assert(isa(img, 'single'), 'incorrect type');
assert(isequal(img,[0,0,0;0,1,0;0,0,0]), 'img incorrect');

%% Test two
% nodes = sig.node.from({net.origin('d'), pos, dims, ori})';
% [pos, dims, ori] = deal(nodes(2:end)); 
pos = net.origin('position');
dims = net.origin('dimentions');
ori = net.origin('orientation');

[layer, img] = vis.rectLayer(pos, dims, ori);
pos.post([10, 5]);
dims.post([50, 50]);
ori.post(12);

% Verify layer properties correctly set
assert(all(layer.texOffset.Node.CurrValue == pos.Node.CurrValue), ...
  'texOffset incorrect');
assert(layer.texAngle.Node.CurrValue == ori.Node.CurrValue, ...
  'texAngle incorrect');
assert(all(layer.size.Node.CurrValue == 150), 'size incorrect');
% Verify image is correct
assert(isa(img, 'single'), 'incorrect type');
assert(isequal(img,[0,0,0;0,1,0;0,0,0]), 'img incorrect');
