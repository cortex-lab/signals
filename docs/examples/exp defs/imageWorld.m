function imageWorld(t, evts, p, vs, ~, ~, ~)
% IMAGEWOLD Presentation of Marius's image set
%  Displays images loaded from a directory in a random order.  Images are
%  loaded at stimulus off (or at experiment start for the first image) and
%  are presented for p.onDuration seconds followed by an inter-trial
%  interval of p.offDuration seconds.  Each image is shown n times in a row
%  where n = p.repeats.  The numRepeats paramter defines the number of
%  images to be shown.  If numRepeats is greater than the number of images
%  in the folder, the experiment will stop when all images in the folder
%  have been shown
%
%  Image directory must contain image files as MAT files named imgN where N
%  = {1, ..., N total images}.
%
% See also VIS.IMAGE
%
% 2018-10-31 MW created

%% parameters
% Image directory
imgDir = p.imgDir.skipRepeats(); % Updates once per session
N = imgDir.map(@file.list).map(@numel); % Get number of images
imgIds = N.map(@randperm); % Randomize order of images

%% Deine the trial structure
on = evts.newTrial.to(evts.newTrial.delay(p.onDuration.map(@timeSampler)));
off = at(true, on == false); % `at` makes sure off only ever updates to true
% If you want each image to repeat a set number of times...  Here when
% endTrial is false idx will update with the same value as before,
% repeating the image.
showNext = evts.repeatNum == p.repeats;
evts.endTrial = showNext.at(off).delay(p.onDuration.map(@timeSampler));
% evts.endTrial = off.delay(p.offDuration); % Show each once

% Create index signal for grabbing the image each trial
idx = merge(evts.expStart.map(true), showNext.at(off).scan(@plus, 1));
number = skipRepeats(imgIds(idx)); % won't reload the texture on repeats
numberStr = number.map(@num2str); % convert to str for filepath

%% define the visual stimulus
% Load our next image from file at stimulus off
imgArr = imgDir.map2(numberStr, ...
  @(dir,num)loadVar(fullfile(dir, ['img' num '.mat']), 'img'));

vs.stimulus = vis.image(t, imgArr.map(@rescale)); % Rescale to [0 255]
vs.stimulus.show = on;

%% Exp stop and log events
evts.expStop = at(true, idx == N); % Session ends when all images shown.
evts.stimulusOn = on;
evts.index = idx;
evts.num = number;

%% Parameter defaults
% See timeSampler for full details on what values the *Delay paramters can
% take.  Conditional perameters are defined as having ncols > 1, where each
% column is a condition.  All conditional paramters must have the same
% number of columns.
try
  imgDir = '\\zserver.cortexlab.net\Data\pregenerated_textures\Marius\proc\selection2800';
  p.imgDir = imgDir;
  p.onDuration = 5; % How long to present each image for (seconds)
  p.offDuration = 2; % Time between each image presentation (seconds)
  p.repeats = 2; % The number of times in a row to repeat each image  
catch 
  % NB: At the start of a Signals experiment (as opposed to when you call
  % inferParameters) this catch block is executed.  Therefore you could
  % preload the images here during the initiazation phase.  This isn't
  % really necessary and may be commented out.
  preLoad(imgDir);
end

end

%% Helper functions
function duration = timeSampler(time)
% TIMESAMPLER Sample a time from some distribution
%  If time is a single value, duration is that value.  If time = [min max],
%  then duration is sampled uniformally.  If time = [min, max, time const],
%  then duration is sampled from a exponential distribution, giving a flat
%  hazard rate.  If numel(time) > 3, duration is a randomly sampled value
%  from time.
%
% See also exp.TimeSampler
if nargin == 0; duration = 0; return; end
switch length(time)
  case 3 % A time sampled with a flat hazard function
    duration = time(1) + exprnd(time(3));
    duration = iff(duration > time(2), time(2), duration);
  case 2 % A time sampled from a uniform distribution
    duration = time(1) + (time(2) - time(1))*rand;
  case 1 % A fixed time
    duration = time(1);
  otherwise % Pick on of the values
    duration = randsample(time, 1);
end
end

function preLoad(imgDir)
% PRELOAD Load images into memory to speed up retrieval
%  The burgbox function `loadVar` caches the images it loads and so long as
%  the files have not been modified, will return the cached image rather
%  than re-loading from the disk.  Calling this function either at expStart
%  or independent of any signals will load all the images into memory
%  well before the stimuli are presented.  This may be useful if you want
%  to show them in quick succession.  
%
% See also loadVar, clearCBToolsCache

% Clear any previously cached images so that memory doesn't blow up
clearCBToolsCache % Comment out to keep images cached between experiments
imgs = dir(fullfile(imgDir, '*.mat')); % Get all images from directory
loadVar(strcat({imgs.folder},'\',{imgs.name})); % Load into memory
end

function img = rescale(img)
% RESCALE Rescales image from [-1 1] to [0 255]
%  The original image set this was written for comprised arrays of values
%  normalized between -1 and 1.  This helper function rescales them to the
%  correct range.  Note that images may also be between 0 and 1.
img = max(img,-1); img = min(img, 1);
img = (img*128+128);
end