net = sig.Net;

%% Test one
pos = [10 5];
dims = [50 50];
ori = 12;
[layer, img] = vis.rectLayer(pos, dims, ori);
% Verify layer properties correctly set
testCase.verifyEqual(layer.interpolation, 'nearest', 'interpolation incorrect');
testCase.verifyEqual(layer.texOffset, pos, 'texOffset incorrect');
testCase.verifyEqual(layer.texAngle, ori, 'texAngle incorrect');
testCase.verifyEqual(layer.size, [150 150], 'size incorrect');
testCase.verifyTrue(~layer.isPeriodic, 'isPeriodic set to true');
% Verify image is correct
testCase.verifyTrue(isa(img, 'single'), 'incorrect type');
testCase.verifyTrue(isequal(img,[0,0,0;0,1,0;0,0,0]), 'img incorrect');

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
testCase.verifyEqual(layer.texOffset.Node.CurrValue, pos.Node.CurrValue, ...
  'texOffset incorrect');
testCase.verifyEqual(layer.texAngle.Node.CurrValue, ori.Node.CurrValue, ...
  'texAngle incorrect');
testCase.verifyEqual(layer.size.Node.CurrValue, [150 150], 'size incorrect');
% Verify image is correct
testCase.verifyTrue(isa(img, 'single'), 'incorrect type');
testCase.verifyTrue(isequal(img,[0,0,0;0,1,0;0,0,0]), 'img incorrect');
