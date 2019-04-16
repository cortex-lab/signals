function signalsPong(t, events, p, visStim, inputs, outputs, audio)
% SIGNALSPONG runs a simple version of the classic game, pong, in Signals
%
% This expdef runs a fairly simple one-player version of pong. The game
% pits the experimenter against a CPU player - the first to reach a 
% pre-defined score (5, by default) wins. During gameplay, the ball's 
% velocity is constant, and the ball's trajectory changes randomly upon 
% contact with a paddle or the wall.
%
% This exp def should be run via the ExpTestPanel GUI (exp.ExpTest)
% 
% Example: 
%  expTestPanel = exp.ExpTest('signalsPong');
%
% Author: Jai Bhagat - adapted from Andy Peters
%
% *Note: The parameters the experimenter can play with are defined and 
% explained at the bottom of this exp def

%% Initializations for troubleshooting in command window:
% net = sig.Net;
% t = net.origin('t');
% events = sig.Registry;
% events.expStart = net.origin('expStart');
% events.newTrial = net.origin('newTrial');
% events.expStop = net.origin('expStop');
% events.endTrial = net.origin('endTrial');
% inputs = sig.Registry;
% inputs.wheel = net.origin('wheel');
% getYPos = @GetMouse;

%% Define constants for the world (points of control)
% The entire scope of the game is treated as a world, and the game's data
% at any given time is treated as a world state

% The Signals exp def trial structure is set-up so that a trial ends when a
% score occurs, and the experiment ends when the player or cpu reaches
% 'scoretoWin'

% Experiment time constants
updateTime = 0.01; % how often to update the world (i.e. move onto the next state) in s

% Arena constants
%arenaSz = p.arenaSz; % [w h] in visual degrees
arenaSz = [180 105];
arenaColor = p.arenaColor; % RGB color vector
arenaCenterX = 0; % azimuth in visual degrees
arenaCenterY = 0; % altitude in visual degrees

% Ball constants
%ballSz = p.ballSz; % [majorAxis minorAxis] in visual degrees
ballSz = [5 5];
ballInitAngle = events.newTrial.map(@(~) rand*360); % initial angle of ball
ballVel = p.ballVel; % ball velocity in visual degrees per second
ballInitX = 0; % ball initial x-position
ballInitY = 0; % ball initial y-position
ballColor = p.ballColor; % RGB color vector
showBallDelay = events.newTrial.delay(0.3); % time (based on trial epoch) when ball is visible

% Paddle constants
%playerPaddleSz = p.playerPaddleSz; % [w h] in visual degrees
%cpuPaddleSz = p.cpuPaddleSz;
playerPaddleSz = [5 20];
cpuPaddleSz = [5 20];
playerPaddleColor = p.playerPaddleColor; % RGB color vector
cpuPaddleColor = p.cpuPaddleColor; % RGB color vector
cpuPaddleX = -p.arenaSz(1)/2 + p.cpuPaddleSz(1); % azimuth in visual degrees
cpuPaddleInitY = 0; % altitude in visual degrees
cpuPaddleCoverage = p.cpuPaddleCoverage; % coverage of cpu paddle for ball, as a fraction of ball y-position
%cpuPaddleVelInit = 0; % y-velocity in visual degrees per second
%cpuPaddleGain = 0.75; % gain for paddle velocity as fraction of ball velocity
%cpuPaddleDelay = 0.3; % seconds that cpu paddle lags behind ball
playerPaddleX = p.arenaSz(1)/2 - p.cpuPaddleSz(1); % near right edge of screen 

% Mouse cursor constants
cursorGain = 0.1; % set gain for cursor

% Game constants
scoreToWin = p.scoreToWin;

%% Define a world state
% A state is a number - the time since experiment start. Here we use a
% slower version of Signals' 't' signal in order to reduce the
% computational load

% set 'tUpdate': a slower version of 't'
tUpdateMod = t - mod(t, updateTime);
tUpdate = tUpdateMod.skipRepeats;
startTime = events.expStart.map(true).map(@(~) GetSecs);
curExpTime = tUpdate - startTime;

%% Set hardware input (mouse cursor) parameters

wheel = inputs.wheel; % get signal for wheel (which is auto-linked to mouse cursor)

% create a function to return y-position of cursor
  function yPos = getYPos()
    % GETYPOS uses PTB's 'GetMouse' function to return the cursor 
    % y-coordinate, in pixels
    [~, yPos] = GetMouse();
  end

% get cursor's initial y-position
cursorInitialY = events.expStart.map(true).map(@(~) getYPos);

%% Define how the paddles' interactions update the world

% 'cpuPaddleY' needs to be an origin signal so that it can interact
% mutually dependently with 'ballY': 'ballY' <--> 'cpuPaddleY'. (cpu paddle
% will follow the position of the ball, and the ball position will update
% when hitting cpu paddle).
% As an origin signal, it can and will be posted into (via a listener) when
% 'ballY' updates
cpuPaddleY = t.Node.Net.origin('cpuPaddleY');

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
% 'ballX' <--> 'ballAngle' 'ballY' <--> 'ballAngle'. (ball angle determines
% the ball position, and when ball comes into contact with a paddle or
% wall, then ball position will determine the new ball angle).
% As origin signals, they can and will be posted into (via listeners) when  
% 'ballAngle' updates

%ballAngle = t.Node.Net.origin('ballAngle');
ballX = t.Node.Net.origin('ballX');
ballY = t.Node.Net.origin('ballY');

% define scoring events
playerScored = ballX < -(arenaSz(1)/2);
cpuScored = ballX > (arenaSz(1)/2);
playerScoredInstant = playerScored.to(~playerScored);
cpuScoredInstant = cpuScored.to(~cpuScored);
anyScored = playerScoredInstant | cpuScoredInstant;

events.endTrial = anyScored.then(1);

% keep track of running score
playerScore = playerScoredInstant.scan(@plus,0);
cpuScore = cpuScoredInstant.scan(@plus,0);

% define the end of the game
endGame = merge((playerScore == scoreToWin), (cpuScore == scoreToWin));
events.expStop = endGame.then(1);

% define ball contact with walls or paddles
wallContact = abs(ballY) > arenaSz(2)/2;
playerPaddleContact = (playerPaddleX-ballX) < (playerPaddleSz(1)/2) &...
  abs((playerPaddleY-ballY)) < (playerPaddleSz(2)/2);
cpuPaddleContact = (ballX-cpuPaddleX) < (cpuPaddleSz(1)/2) &...
  abs((cpuPaddleY-ballY)) < (cpuPaddleSz(2)/2);

% for initialization purposes, define contact to also occur at the start
% of each new trial
contact = merge(events.newTrial.then(1), ...
  wallContact.to(~wallContact),... 
  playerPaddleContact.to(~playerPaddleContact),... 
  cpuPaddleContact.to(~cpuPaddleContact));
deflection = contact.map(@(~) rand*90);


% 8 conditions for deflection: 1) off top towards player; 2) off top towards 
% cpu; 3) off bottom towards player; 4) off bottom towards cpu;
% 5) off player from bottom; 6) off player from top; 7) off cpu from bottom;
% 8) off cpu from top

% deflection = cond(... 
%   ((ballY < (-arenaSz(2)/2 + 1)) & ((0 < ballAngle) & (ballAngle < 90))), randi([270, 360]),... 
%   ((ballY < (-arenaSz(2)/2 + 1)) & ((90 < ballAngle) & (ballAngle < 180))), randi([180, 270]),... 
%   ((ballY > (arenaSz(2)/2 - 1)) & ((270 < ballAngle) & (ballAngle < 360))), randi([0, 90]),...
%   ((ballY > (arenaSz(2)/2 - 1)) & ((180 < ballAngle) & (ballAngle < 270))), randi([90, 180]),...
%   ((((arenaSz(2)/2 - 1) < ballY) & (ballY < (arenaSz(2)/2 + 1))) & ((0 < ballAngle) & (ballAngle < 90))), randi([90, 180]),...
%   ((((arenaSz(2)/2 - 1) < ballY) & (ballY < (arenaSz(2)/2 + 1))) & ((270 < ballAngle) & (ballAngle < 360))), randi([180, 270]),...
%   ((((arenaSz(2)/2 - 1) < ballY) & (ballY < (arenaSz(2)/2 + 1))) & ((90 < ballAngle) & (ballAngle < 180))), randi([0, 90]),...
%   ((((arenaSz(2)/2 - 1) < ballY) & (ballY < (arenaSz(2)/2 + 1))) & ((180 < ballAngle) & (ballAngle < 270))), randi([270, 360]));
% newAngle = deflection.at(contact);
% ballAngleToPost = merge(ballInitAngle, newAngle);

% ball position is calculated by: (1) ball velocity * (2) time 
% + (3) ball offset value + (4) ball initial value)
% (1) is determined by ball angle; (2) is determined by time of 
% last contact point subtracted from running experiment time; (3) is 
% determined by pall position at last contact point; (4) is initialized
% at the top of this exp def.

% 'ballAngle' sets 'ballVelX' and 'bellVelY'
% use 'merge' with 'ballAngle' to make sure it takes 'ballInitAngle' as
% it's initial value at experiment start
ballAngle = merge(ballInitAngle,... 
  deflection.scan(@plus, ballInitAngle));

% ball velocity/angle direction references:
% at 0 degrees all velocity is in positive X, at 90 degrees all velocity is
% in positive Y, at 180 degrees all velocity is in negative X, at 270 
% degrees all velocity is in negative Y
ballVelX = ballVel * -cos(deg2rad(360-ballAngle));
ballVelY = ballVel * sin(deg2rad(ballAngle));

% get ball position and exp time at contact
% use 'merge' to initialize these signals at experiment start
ballXAtContactOrScore = merge(anyScored.then(0),...
  ballX.at(contact));
ballYAtContactOrScore = merge(anyScored.then(0),...
  ballY.at(contact));
expTimeAtContactOrScore = merge(anyScored.then(curExpTime-updateTime),...
  curExpTime.at(contact));

% get ball contact offset values
ballXContactOffset = cond(ballXAtContactOrScore < 0, ballXAtContactOrScore+1,... 
  ballXAtContactOrScore > 0, ballXAtContactOrScore-1,... 
  ballXAtContactOrScore == 0, 0, true, 0);
ballYContactOffset = cond(ballYAtContactOrScore < 0, ballYAtContactOrScore+1,... 
  ballYAtContactOrScore > 0, ballYAtContactOrScore-1,... 
  ballYAtContactOrScore == 0, 0, true, 0);

% get running time from last contact point
timeDelta = (curExpTime - expTimeAtContactOrScore);

% calculate new velocity and contact offset values after contact
ballVelXAfterContact = ballVelX.at(timeDelta);
ballXContactOffsetAfterContact = ballXContactOffset.at(ballVelXAfterContact);
ballVelYAfterContact = ballVelY.at(timeDelta);
ballYContactOffsetAfterContact = ballYContactOffset.at(ballVelYAfterContact);

% define mutually dependent signals' interactions
% ensure the order of updates relating to ball position at a contact point
% is:
% 1) 'expTimeAtContact', 2)'ballVel_', 3) 'ball_AtContact'
ballXToPost = merge( events.newTrial.then(ballInitX),...
  (timeDelta * ballVelXAfterContact + ballXContactOffsetAfterContact + ... 
  ballInitX) );
ballYToPost = merge( events.newTrial.then(ballInitY),...
  (timeDelta * ballVelYAfterContact + ballYContactOffsetAfterContact + ... 
  ballInitY) );
cpuPaddleYToPost = ballYToPost * cpuPaddleCoverage;

% t.Node.Listeners = [t.Node.Listeners,...
%   ballAngleToPost.delay(updateTime).into(ballAngle),...
%   ballXToPost.delay(updateTime).into(ballX),... 
%   ballYToPost.delay(updateTime).into(ballY),...
%   cpuPaddleYToPost.delay(updateTime).into(cpuPaddleY),...
%   events.endTrial.onValue(@(~)... 
%     fprintf('<strong> Score! Player 1: %d cpu: %d </strong>\n',... 
%     playerScore.Node.CurrValue, cpuScore.Node.CurrValue)),...
%   events.expStop.onValue(@(~)... 
%     fprintf('<strong> Game Over! Final Score: Player 1: %d cpu: %d </strong>\n',... 
%     playerScore.Node.CurrValue, cpuScore.Node.CurrValue)) 
%     ];  

% use the 't' signal's listeners to update the origin signals 
% 'ballX', 'ballY', and 'cpuPaddleY'
% use 'delay' to ensure infinite recursion doesn't occur
% add listeners each time there is a score, and for when game ends
t.Node.Listeners = [t.Node.Listeners,...
  ballXToPost.delay(updateTime).into(ballX),... 
  ballYToPost.delay(updateTime).into(ballY),...
  cpuPaddleYToPost.delay(updateTime).into(cpuPaddleY),...
  events.endTrial.onValue(@(~)... 
    fprintf('<strong> Score! Player 1: %d cpu: %d </strong>\n',... 
    playerScore.Node.CurrValue, cpuScore.Node.CurrValue)),...
  events.expStop.onValue(@(~)... 
    fprintf('<strong> Game Over! Final Score: Player 1: %d cpu: %d </strong>\n',... 
    playerScore.Node.CurrValue, cpuScore.Node.CurrValue)) 
    ];
  
% post initial values into our origin signals *after* the signals dependent
% on them have been defined
% ballAngle.post(ballInitAngle);
ballX.post(ballInitX);
ballY.post(ballInitY);
cpuPaddleY.post(cpuPaddleInitY);

% create the paddles as 'vis.patch' rectangle subscriptable signals
playerPaddle = vis.patch(t, 'rectangle');
playerPaddle.dims = playerPaddleSz;
playerPaddle.altitude = playerPaddleY;
playerPaddle.azimuth = playerPaddleX;
playerPaddle.show = true;
playerPaddle.colour = playerPaddleColor;

cpuPaddle = vis.patch(t, 'rectangle');
cpuPaddle.dims = cpuPaddleSz;
cpuPaddle.altitude = cpuPaddleY;
cpuPaddle.azimuth = cpuPaddleX;
cpuPaddle.show = true;
cpuPaddle.colour = cpuPaddleColor;

% create arena as a 'vis.patch' rectangle subscriptable signal
arena = vis.patch(t, 'rectangle');
arena.dims = arenaSz;
arena.colour = arenaColor;
arena.azimuth = arenaCenterX;
arena.altitude = arenaCenterY;
arena.show = true;

% create the ball as a 'vis.patch' circle subscriptable signal
ball = vis.patch(t, 'circle');
ball.dims = ballSz;
ball.altitude = ballY;
ball.azimuth = ballX;
ball.show = showBallDelay.to(events.endTrial);
ball.colour = ballColor;

% assign the arena, paddles, and ball to the 'visStim' subscriptable signal
% handler
visStim.arena = arena;
visStim.playerPaddle = playerPaddle;
visStim.cpuPaddle = cpuPaddle;
visStim.ball = ball;

% parameters for experimenter in GUI
try
  p.arenaColor = [0 0 0]'; % RGB color vector
  p.ballColor = [1 1 1]'; % RGB color vector
  p.playerPaddleColor = [1 1 1]'; % RGB color vector
  p.cpuPaddleColor = [1 1 1]'; % RGB color vector
  p.arenaSz = [180 105]'; % [w h] in visual degrees
  p.ballVel = 60; % ball velocity in visual degrees per second
  p.cpuPaddleCoverage = 0.75; % coverage of cpu paddle for ball, as a fraction of ball y-position
  p.ballSz = [5 5]'; % [majorAxis minorAxis] in visual degrees
  p.playerPaddleSz = [5 20]'; % [w h] in visual degrees
  p.cpuPaddleSz = [5 20]';
  p.scoreToWin = 5;
catch % ex
  % disp(getReport(ex))
end

end
