% vis.squareWaveLayer test

%% Test 1: vis.grating default values
azimuth = 0; spatialFreq = 1/15; phase = 0; orientation = 0;
[layer, image] = vis.squareWaveLayer(azimuth, spatialFreq, phase, orientation);
TestAns = round([layer.texOffset(1), layer.texAngle, layer.size(1)], 4);
ExpectedAns = [11.2500 0 15.0000];
assert(isequal(TestAns,ExpectedAns), 'Test 1 failed.');

%% Test 2: Negative Azimuth
azimuth = -90; spatialFreq = 1/15; phase = 0; orientation = 0;
[layer, image] = vis.squareWaveLayer(azimuth, spatialFreq, phase, orientation);
TestAns = round([layer.texOffset(1), layer.texAngle, layer.size(1)],4);
ExpectedAns = [-78.7500 0 15.0000];
assert(isequal(TestAns,ExpectedAns), 'Test 2 failed.');

%% Test 3: High Spatial Frequency
azimuth = 0; spatialFreq = 2; phase = 0; orientation = 0;
[layer, image] = vis.squareWaveLayer(azimuth, spatialFreq, phase, orientation);
TestAns = round([layer.texOffset(1), layer.texAngle, layer.size(1)],4);
ExpectedAns = [0.3750 0 0.5000];
assert(isequal(TestAns,ExpectedAns), 'Test 3 failed.');


%% Test 4: Negative Phase
azimuth = 0; spatialFreq = 1/15; phase = -90; orientation = 0;
[layer, image] = vis.squareWaveLayer(azimuth, spatialFreq, phase, orientation);
TestAns = round([layer.texOffset(1), layer.texAngle, layer.size(1)],4);
ExpectedAns = [6.3908 0 15.0000];
assert(isequal(TestAns,ExpectedAns), 'Test 4 failed.');

%% Test 5: Negative Orientation
azimuth = 0; spatialFreq = 1/15; phase = 0; orientation = -90;
[layer, image] = vis.squareWaveLayer(azimuth, spatialFreq, phase, orientation);
TestAns = round([layer.texOffset(1), layer.texAngle, layer.size(1)],4);
ExpectedAns = [11.2500 -90.0000 15.0000];
assert(isequal(TestAns,ExpectedAns), 'Test 5 failed.');

%% Test 6: Non-zero values for all input args
azimuth = 45; spatialFreq = 7/15; phase = 30; orientation = 60;
[layer, image] = vis.squareWaveLayer(azimuth, spatialFreq, phase, orientation);
TestAns = round([layer.texOffset(1), layer.texAngle, layer.size(1)],4);
ExpectedAns = [23.6242 60.0000 2.1429];
assert(isequal(TestAns,ExpectedAns), 'Test 6 failed.');

%% Test 7: Impossible Spatial Frequency 
azimuth = 45; spatialFreq = -1/15; phase = 30; orientation = 60;
[layer, image] = vis.squareWaveLayer(azimuth, spatialFreq, phase, orientation);
TestAns = round([layer.texOffset(1), layer.texAngle, layer.size(1)],4);
ExpectedAns = [14.6303 60.0000 -15.0000];
assert(isequal(TestAns,ExpectedAns), 'Test 7 failed.');