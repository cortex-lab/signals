function signalsPong(t, events, params, visStim, inputs, outputs, audio)
% SIGNALSPONG runs a simple version of the classic game, pong, in signals
%
% This expdef runs a fairly simple version of pong. The ball's velocity is 
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
ballInitAngle = 270; %todo: change back ball initial angle
ballVel = 5; % ball velocity in visual degrees per second
ballInitX = 0; % ball initial x-position
ballInitY = 0; % ball initial y-position
ballColour = [1 1 1]; % RGB color vector

% Paddle constants
paddleSz = [5,20]; % [w h] in visual degrees
cpuPaddleColour = [1 1 1]; % RGB color vector
cpuPaddleX = -90; % azimuth in visual degrees
cpuPaddleInitY = 0; % altitude in visual degrees
cpuPaddleVelInit = 0; % y-velocity in visual degrees per second
cpuPaddleGain = 0.75; % gain for paddle velocity as fraction of ball velocity
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
events.cpuPaddleVel = cpuPaddleVel;
% create a signal that will update the y-position of the cpu's paddle
% based on 'ballVelY'
cpuPaddleYUpdateVal = cpuPaddleVel * curExpTime + cpuPaddleInitY;
events.cpuPaddleYUpdateVal = cpuPaddleYUpdateVal;
% make sure the y-value of the cpu's paddle is within the screen bounds
cpuPaddleY = cond(cpuPaddleYUpdateVal > arenaSz(2)/2, arenaSz(2)/2,...
  cpuPaddleYUpdateVal < -arenaSz(2)/2, -arenaSz(2)/2,... 
  true, cpuPaddleYUpdateVal);
events.cpuPaddleY = cpuPaddleY;

% create a signal that will update the y-position of the player's paddle
% based on cursor
playerPaddleYUpdateVal =... 
  (wheel.map(@(~) getYPos) - cursorInitialY) * cursorGain;
% make sure the y-value of the player's paddle is within the screen bounds
playerPaddleY = cond(playerPaddleYUpdateVal > arenaSz(2)/2, arenaSz(2)/2,...
  playerPaddleYUpdateVal < -arenaSz(2)/2, -arenaSz(2)/2,... 
  true, playerPaddleYUpdateVal);
events.playerPaddleY = playerPaddleY;

%% Define how ball's interactions update the world:

% 'ballX' and 'ballY' need to be origin signals so that they can interact 
% mutually dependently with 'ballAngle': 
% 'ballX' <--> 'ballAngle' 'ballY' <--> 'ballAngle'.
% As origin signals, they can and will be posted into (via listeners) when  
% 'ballAngle' updates
ballX = t.Node.Net.origin('ballX');
ballY = t.Node.Net.origin('ballY');
events.ballX = ballX;
events.ballY = ballY;

% ball velocity/angle direction references:
% at 0 degrees all velocity is in positive X, at 90 degrees all velocity is
% in positive Y, at 180 degrees all velocity is in negative X, at 270 
% degrees all velocity is in negative Y

% initialize ball angle randomly between 0-360 degrees, and when ball comes 
% into contact with a wall or paddle, change it's direction by 180 degrees
%ballInitAngle = 360 * events.newTrial.map(@(~) rand);
wallContact = abs(ballY) > arenaSz(2)/2;
events.wallContact = wallContact;
playerPaddleContact = (playerPaddleX-ballX) < (paddleSz(1)/2) &...
  (playerPaddleY-ballY) < (paddleSz(2)/2);
events.playerPaddleContact = playerPaddleContact;
cpuPaddleContact = (ballX-cpuPaddleX) < (paddleSz(1)/2) &...
  (cpuPaddleY-ballY) < (paddleSz(2)/2);
events.cpuPaddleContact = cpuPaddleContact;
contact = merge(wallContact, playerPaddleContact, cpuPaddleContact);
events.contact = contact;
contactInstant = contact.then(180);
events.contactInstant = contactInstant;

% 'ballAngle' sets 'ballVelX' and 'bellVelY'
% use 'merge' with 'ballAngle' to make sure it takes 'ballInitAngle' as
% it's initial value at experiment start
ballAngle = merge(contactInstant.scan(@minus, ballInitAngle), ...
  events.expStart.map(true).then(ballInitAngle));
events.ballAngle = ballAngle;
ballVelX = ballVel * -cos(deg2rad(360-ballAngle));
events.ballVelX = ballVelX;
ballVelY = ballVel * sin(deg2rad(ballAngle));
events.ballVelY = ballVelY;

% get ball position and exp time at contact
ballXAtContact = merge(ballX.at(contact),... 
  events.expStart.map(true).then(0));
ballYAtContact = merge(ballY.at(contact),...
  events.expStart.map(true).then(0));
expTimeAtContact = merge(curExpTime.at(contact),...
  events.expStart.map(true).then(0));

% define mutually dependent signals' interactions:
% 'ballVelX' and 'ballVelY' set 'ballX', 'ballY' and 'cpuPaddleY'
ballXToPost = ballVelX * (curExpTime - expTimeAtContact) + ballXAtContact...
  + ballInitX;
ballYToPost = ballVelY * (curExpTime - expTimeAtContact) + ballYAtContact...
  + ballInitY;
events.ballXToPost = ballXToPost;
events.ballYToPost = ballYToPost;
cpuPaddleVelToPost = ballVelY * cpuPaddleGain; % paddle velocity as fraction of ball velocity in visual degrees per second

% use the 't' signal's listeners to listen to when 'ballVelX' and
% 'ballVelY' update in order to update 'ballX', 'ballY', and 'cpuPaddleVel'
% use 'delay' to ensure infinite recursion doesn't occur
t.Node.Listeners = [t.Node.Listeners,... 
  ballXToPost.delay(0.01).into(ballX),... 
  ballYToPost.delay(0.01).into(ballY),... 
  cpuPaddleVelToPost.delay(0.01).into(cpuPaddleVel)];

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
ball.altitude = ballY;
ball.azimuth = ballX;
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











