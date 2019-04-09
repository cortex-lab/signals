function signalsPong(t, events, params, visStim, inputs, outputs, audio)
% SIGNALSPONG runs a simple version of the classic game, pong, in signals
%
% This expdef runs a fairly simple version of pong. The ball's velocity 
% constant, and the ball's trajectory does not depend on where on a paddle
% or wall it hits, but only on the angle at which it hits.
%
% This exp def should be run via the ExpTestPanel GUI (exp.ExpTest)
% 
% Author: Jai Bhagat - adapted from Andy Peters
%
% Example: 
%  expTestPanel = exp.ExpTest('signalsPong');
%
% todo: add world constants as signals parameters

%% Define constants for the world (points of control)
% The entire scope of the game is treated as a world, and the game's data
% at any given time is treated as a world state

% Experiment time constants
updateTime = 0.01; % how often to update the world (i.e. move onto the next state) in s

% Arena constants
arenaSz = [190,105]; % [w h] in visual degrees
arenaColour = [0 0 0]; % RGB color vector
arenaCenterX = 0; % azimuth in visual degrees
arenaCenterY = 0; % altitude in visual degrees

% Ball constants
ballSz = [5,5]; % [majorAxis minorAxis] in visual degrees
ballInitX = 0; % ball initial x-position
ballInitY = 0; % ball initial y-position
ballVel = 3; % ball velocity in visual degrees per second
ballColour = [1 1 1]; % RGB color vector

% Paddle constants
paddleSz = [5,20]; % [w h] in visual degrees
cpuPaddleColour = [1 1 1]; % RGB color vector
cpuPaddleX = -90; % azimuth in visual degrees
cpuPaddleInitY = 0; % altitude in visual degrees
cpuPaddleVelInit = 0; % y-velocity in visual degrees per second
playerPaddleColour = [1 1 1]; % RGB color vector
playerPaddleX = 90; % near right edge of screen 

% Mouse cursor constants
cursorGain = 0.33; % set gain for cursor

%% Define a world state
% A state is a number - the time since experiment start. Here we use a
% slower version of Signals' 't' signal in order to reduce the
% computational load

% set 'tUpdate': a slower version of 't'
tUpdateMod = t - mod(t, updateTime);
tUpdate = tUpdateMod.skipRepeats;
startTime = events.expStart.map(true).map(@(~) GetSecs);
curExpTime = tUpdate - startTime;

%% Set mouse cursor parameters using wheel
% Hardware input and mouse cursor parameters
wheel = inputs.wheel; % get signal for wheel

% create a function to return y-position of cursor
  function yPos = getYPos()
    % GETYPOS uses PTB's 'GetMouse' function to return the cursor 
    % y-coordinate, in pixels
    [~, yPos] = GetMouse();
  end

% get cursor's initial y-position
cursorInitialY = events.expStart.map(true).map(@(~) getYPos);

%% Define how the paddles' interactions update the world

% 'cpuPaddleVel' needs to be an origin signal so that it can interact
% mutually dependently with 'ballVelY': 'ballVelY' <--> 'cpuPaddleVel'.
% As an origin signal, it can and will be posted into (via a listener) when
% 'ballVelY' updates
cpuPaddleVel = t.Node.Net.origin('cpuPaddleVel'); % y-velocity of the cpu paddle in visual degrees per second
% create a signal that will update the y-position of the cpu's paddle
% based on 'ballVelY'
cpuPaddleYUpdateVal = cpuPaddleVel * curExpTime + cpuPaddleInitY;
% make sure the y-value of the cpu's paddle is within the screen bounds
cpuPaddleY = cond(cpuPaddleYUpdateVal > arenaSz(2)/2, arenaSz(2)/2,...
  cpuPaddleYUpdateVal < -arenaSz(2)/2, -arenaSz(2)/2,... 
  true, cpuPaddleYUpdateVal);

% create a signal that will update the y-position of the player's paddle
% based on cursor
playerPaddleYUpdateVal =... 
  (wheel.map(@(~) getYPos) - cursorInitialY) * cursorGain;
% make sure the y-value of the player's paddle is within the screen bounds
playerPaddleY = cond(playerPaddleYUpdateVal > arenaSz(2)/2, arenaSz(2)/2,...
  playerPaddleYUpdateVal < -arenaSz(2)/2, -arenaSz(2)/2,... 
  true, playerPaddleYUpdateVal);

%% Define how ball's interactions update the world:

% 'ballX' and 'ballY' need to be origin signals so that they can interact 
% mutually dependently with 'ballAngle': 
% 'ballX' <--> 'ballAngle' 'ballY' <--> 'ballAngle'.
% As origin signals, they can and will be posted into (via listeners) when  
% 'ballAngle' updates
ballX = t.Node.Net.origin('ballX');
ballY = t.Node.Net.origin('ballY');

% ball velocity/angle direction references:
% at 0 degrees all velocity is in positive X, at 90 degrees all velocity is
% in positive Y, at 180 degrees all velocity is in negative X, at 270 
% degrees all velocity is in negative Y

% initialize ball angle randomly between 0-360 degrees, and when ball comes 
% into contact with a wall or paddle, change it's direction by 180 degrees
ballInitAngle = 360 * events.newTrial.map(@rand);
events.ballInitAngle = ballInitAngle;
contact = merge(abs(ballY) > (arenaSz(2)/2),... % wall contact
  ((ballX - playerPaddleX) < (paddleSz(1)/2)) & ((ballY-playerPaddleY) < (paddleSz(2)/2)),... % player paddle contact 
  ((ballX - cpuPaddleX) < (paddleSz(1)/2)) & ((ballY-cpuPaddleY) < (paddleSz(2)/2))... % cpu paddle contact
  ); 
contactInstant = contact.then(180);

% 'ballAngle' sets 'ballVelX' and 'bellVelY'
ballAngle = contactInstant.scan(@minus, ballInitAngle); 
events.ballAngle = ballAngle;
ballVelX = ballVel * -cos(deg2rad(360-ballAngle));
events.ballVelX = ballVelX;
ballVelY = ballVel * sin(deg2rad(ballAngle));
events.ballVelY = ballVelY;

% define mutually dependent signals' interactions:
% 'ballVelX' and 'ballVelY' set 'ballX', 'ballY' and 'cpuPaddleVel'
ballXToPost = ballVelX * curExpTime + ballInitX;
events.ballXToPost = ballXToPost;
ballYToPost = ballVelY * curExpTime + ballInitY;
events.ballYToPost = ballYToPost;
cpuPaddleVelToPost = curExpTime * ballVel; %ballVelY * 0.75; % paddle velocity as fraction of ball velocity in visual degrees per second

% use the 't' signal's listeners to listen to when 'ballVelX' and
% 'ballVelY' update in order to update 'ballX', 'ballY', and 'cpuPaddleVel'
t.Node.Listeners = [t.Node.Listeners, into(ballXToPost, ballX),... 
  into(ballYToPost, ballY), into(cpuPaddleVelToPost, cpuPaddleVel)];

% post initial values into our origin signals *after* the signals dependent
% on them have been defined
ballX.post(ballInitX);
ballY.post(ballInitY);
cpuPaddleVel.post(cpuPaddleVelInit);

% create the paddles as 'vis.patch' rectangle subscriptable signals
playerPaddle = vis.patch(t, 'rectangle');
playerPaddle.dims = paddleSz;
playerPaddle.altitude = playerPaddleY;
playerPaddle.azimuth = playerPaddleX;
playerPaddle.show = true;
playerPaddle.colour = playerPaddleColour;

cpuPaddle = vis.patch(t, 'rectangle');
cpuPaddle.dims = paddleSz;
cpuPaddle.altitude = cpuPaddleY;
cpuPaddle.azimuth = cpuPaddleX;
cpuPaddle.show = true;
cpuPaddle.colour = cpuPaddleColour;

% create arena as a 'vis.patch' rectangle subscriptable signal
arena = vis.patch(t, 'rectangle');
arena.dims = arenaSz;
arena.colour = arenaColour;
arena.azimuth = arenaCenterX;
arena.altitude = arenaCenterY;
arena.show = true;

% create the ball as a 'vis.patch' circle subscriptable signal
ball = vis.patch(t, 'circle');
ball.dims = ballSz;
ball.altitude = ballVel * curExpTime;
ball.azimuth = ballVel * curExpTime;
ball.show = true;
ball.colour = ballColour;

% assign the arena, paddles, and ball to the 'visStim' subscriptable signal
% handler
visStim.arena = arena;
visStim.playerPaddle = playerPaddle;
visStim.cpuPaddle = cpuPaddle;
visStim.ball = ball;

events.endTrial = events.newTrial.delay(5);

end











