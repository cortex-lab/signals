function mouseTheremin()
% 'Mouse Theremin' implemented using signals. 
%   The function maps the current horizontal curser position to a given
%   frequency.  As the mouse is moved the frequency changes much like a
%   theremin.  Press any key to end the demonstration. Requires
%   PsychToolbox

audioSR = 96e3; %sample rate of audio device
minSamples = round(0.0075*audioSR); %minimum number of samples to output

n = sig.Net;
pos = n.origin('t'); % mouse position
f = 1000*2.^(pos/1000); % transform pos into a log frequency scale
tones = f.map(@packet); % turn frequencies into tones

audh = audstream.fromSignal(tones, audioSR, 2); % put the tqones into the stream

% listen to keyboard events
KbQueueCreate();
KbQueueStart();
try
  disp('Press any key to quit');
  while ~KbQueueCheck
    pos.post(GetMouse);
  end
  %% clean up
  delete(n);
  KbQueueRelease;
catch ex
  delete(n);
  KbQueueRelease;
  rethrow(ex)
end

  function [samples, t] = packet(f)
    % this creates a sinusoid waveform with an integer number of cycles, at
    % least 'minSamples' long of frequency f. this ensures waveform
    % continuity between consecutive sound packets
    %     tic
    wavelengthSamples = audioSR/f;
    nreps = ceil(minSamples/wavelengthSamples);
    nsamples = round(nreps*wavelengthSamples);
    t = linspace(0, nreps*wavelengthSamples/audioSR - 1/audioSR, nsamples);
    samples = repmat(0.125*sin(2*pi*t*f), 2, 1);
  end

end