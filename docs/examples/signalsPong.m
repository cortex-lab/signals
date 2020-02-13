function signalsPong(t, events, p, visStim, inputs, outputs, ~)
% SIGNALSPONG runs a simple version of the classic game, pong, in Signals
%   This exp def runs a fairly simple one-player version of pong. The game
%   pits the experimenter against a CPU player - the first to reach a
%   target score wins. The target score is 5 by default, but is treated as
%   a Signals parameter, and so can be adjusted within the GUI from which
%   this exp def is launched. During gameplay, the ball's velocity is
%   constant, and the ball's trajectory changes randomly upon contact with
%   a paddle or the wall.
%
%   This exp def should be run via the ExpTestPanel GUI (exp.ExpTest)
% 
%   Example: 
%    eui.SignalsTest('signalsPong');
%
% Author: Jai Bhagat - adapted from Andy Peters
%
% Note: The parameters the experimenter can play with are defined and 
% explained at the bottom of this exp def

%% World set-up (points of control)
% The entire scope of the game is treated as a world, and the game's data
% at any given time is treated as a world state

% The Signals exp def trial structure is set-up so that a trial ends when a
% score occurs, and the experiment ends when the player or cpu reaches
% 'targetScore'

% Define world constants:

% Experiment time constants
updateTime = 0.03; % how often to update the world (i.e. move onto the next state) in secs

% Arena constants
arenaSz = [180 105]; % [w h] in visual degrees
arenaColor = [0 0 0]; % RGB color vector
arenaCenterX = 0; % azimuth in visual degrees
arenaCenterY = 0; % altitude in visual degrees

% Ball constants
ballSz = [5 5]; % [majorAxis minorAxis] of ellipse in visual degrees
ballInitAngle = randi([0 360]); % initial angle of ball
ballVel = 50 * updateTime; % ball velocity in visual degrees per second
ballInitX = 0; % ball initial x-position
ballInitY = 0; % ball initial y-position
ballColor = p.ballColor; % RGB color vector
showBallDelay = events.newTrial.delay(0.3); % time (based on trial epoch) when ball is visible

% *note on ball velocity/angle direction references:
% at 0 degrees all velocity is in positive X, at 90 degrees all velocity is
% in positive Y, at 180 degrees all velocity is in negative X, at 270 
% degrees all velocity is in negative Y (see equations to calculate
% 'ballVelX' and 'ballVelY' below)

% Paddle constants
playerPaddleSz = [5 20]; % [w h] in visual degrees
cpuPaddleSz = [5 20]; % [w h] in visual degrees
playerPaddleColor = p.playerPaddleColor; % RGB color vector
cpuPaddleColor = p.cpuPaddleColor; % RGB color vector
playerPaddleX = arenaSz(1)/2 - cpuPaddleSz(1); % azimuth in visual degrees
cpuPaddleX = -arenaSz(1)/2 + cpuPaddleSz(1); % azimuth in visual degrees 
cpuPaddleInitY = 0; % altitude in visual degrees
cpuPaddleCoverage = 0.7; % coverage of cpu paddle for ball, as a fraction of ball y-position

% Mouse cursor constants
cursorGain = 0.2; % set gain for cursor

% Game constants
targetScore = p.targetScore;
initPlayerScore = 0;
initCpuScore = 0;

% A world state is a number - the time since experiment start. Here we will
% use a slower version of Signals' 't' signal to trigger updates for the
% world in order to reduce the computational load by reducing the number of
% updates

% set 'tUpdate', a slower version of 't' (updates every 'updateTime' secs)
tUpdate = skipRepeats(t - mod(t, updateTime));

% get signal for wheel (which is auto-linked to mouse cursor)
wheel = inputs.wheel;

% create a helper function to return y-position of cursor, which will set
% the player paddle
  function yPos = getYPos()
    % GETYPOS uses PTB's 'GetMouse' function to return the cursor 
    % y-coordinate, in pixels
    [~, yPos] = GetMouse();
  end

% get cursor's initial y-position
cursorInitialY = events.expStart.map(@(~) getYPos);

%% Update world state

% create a signal that will update the y-position of the player's paddle
% based on cursor
playerPaddleYUpdateVal =... 
  (wheel.map(@(~) getYPos) - cursorInitialY) * cursorGain;
% make sure the y-value of the player's paddle is within the screen bounds
playerPaddleBounds =... 
  cond(playerPaddleYUpdateVal > arenaSz(2)/2, arenaSz(2)/2,...
  playerPaddleYUpdateVal < -arenaSz(2)/2, -arenaSz(2)/2,... 
  true, playerPaddleYUpdateVal);
% paddle y updates every 'tUpdate' secs
playerPaddleY = playerPaddleBounds.at(tUpdate);

% Create a struct, 'gameDataInit', holding the initial world state
gameDataInit = struct;

% objects that will be updated as the game progresses
gameDataInit.ballAngle = ballInitAngle;
gameDataInit.ballVelX = ballVel * cos(deg2rad(360-ballInitAngle));
gameDataInit.ballVelY = ballVel * -sin(deg2rad(ballInitAngle));
gameDataInit.ballX = ballInitX;
gameDataInit.ballY = ballInitY;
gameDataInit.cpuPaddleY = cpuPaddleInitY;
gameDataInit.playerScore = initPlayerScore;
gameDataInit.cpuScore = initCpuScore;

% objects that are constants that need to be referenced within 'updateGame'
gameDataInit.arenaSz = arenaSz;
gameDataInit.playerPaddleX = playerPaddleX;
gameDataInit.playerPaddleSz = playerPaddleSz;
gameDataInit.cpuPaddleX = cpuPaddleX;
gameDataInit.cpuPaddleSz = cpuPaddleSz;
gameDataInit.ballVel = ballVel;
gameDataInit.cpuPaddleCoverage = cpuPaddleCoverage;

% Create a subscriptable signal, 'gameData', whose fields represent the 
% world state, which gets updated every 'tUpdate' secs
% Feed in 'playerPaddleY' so that 'updateGame' uses 'playerPaddleY' as a
% double instead of as a signal
gameData = playerPaddleY.scan(@updateGame, gameDataInit).subscriptable;

  function gameData = updateGame(gameData, playerPaddleY)
    % UPDATEGAME updates the relevant game data (ball angle, ball velocity,
    % ball position, and cpu paddle y position) every time 'tUpdate'
    % updates
    %
    % Inputs:
    %   'gameData': a struct containing the game data
    %   'playerPaddleY': a double whose value is that of the 
    %     'playerPaddleY' signal
    % 
    % Outputs:
    %   'gameData': a subscriptable signal whose fields match the fields of
    %   the 'gameData' input struct
    
    % define ball contact with walls or paddles
    wallContact = abs(gameData.ballY) > gameData.arenaSz(2)/2;
    playerContact = (gameData.playerPaddleX - gameData.ballX) <...
      (gameData.playerPaddleSz(1)/2) &&... 
      abs((playerPaddleY - gameData.ballY)) <...
      (gameData.playerPaddleSz(2)/2);
    cpuContact = (gameData.ballX - gameData.cpuPaddleX) <... 
      (gameData.cpuPaddleSz(1)/2) &&...
      abs((gameData.cpuPaddleY - gameData.ballY)) <...
      (gameData.cpuPaddleSz(2)/2);
    
    % define scoring events
    playerScored = gameData.ballX < -(gameData.arenaSz(1)/2);
    cpuScored = gameData.ballX > (gameData.arenaSz(1)/2);
    
    % update score if necessary
    if playerScored, gameData.playerScore = gameData.playerScore + 1; end
    if cpuScored, gameData.cpuScore = gameData.cpuScore + 1; end
    
    contactOrScore = wallContact || playerContact || cpuContact... 
                     || playerScored || cpuScored;
    
    if contactOrScore % update ball angle and ball velocity
      
      % change the ball angle & add buffer to prevent infinite recursion:
      
      % 9 cases: 1) off top towards player; 2) off top towards cpu;
      % 3) off bottom towards player; 4) off bottom towards cpu;
      % 5) off player from bottom; 6) off player from top; 
      % 7) off cpu from bottom; 8) off cpu from top; 
      % 9) playerScored | cpuScored
      
      if wallContact && (0 <= gameData.ballAngle) &&... 
          (gameData.ballAngle <= 90) % case 1)
        gameData.ballAngle = randi([270, 360]);
        gameData.ballY = gameData.ballY + 1;
      elseif wallContact && (90 <= gameData.ballAngle) &&... 
          (gameData.ballAngle <= 180) % case 2)
        gameData.ballAngle = randi([180, 270]);
        gameData.ballY = gameData.ballY + 1;
      elseif wallContact && (270 <= gameData.ballAngle) &&... 
          (gameData.ballAngle <= 360) % case 3)
        gameData.ballAngle = randi([0, 90]); 
        gameData.ballY = gameData.ballY - 1;
      elseif wallContact && (180 <= gameData.ballAngle) &&... 
          (gameData.ballAngle <= 270) % case 4)
        gameData.ballAngle = randi([90, 180]);
        gameData.ballY = gameData.ballY - 1;
      elseif playerContact &&...
          (0 <= gameData.ballAngle) && (gameData.ballAngle <= 90) % case 5)
        gameData.ballAngle = randi([90, 180]);
        gameData.ballX = gameData.ballX - 1;
      elseif playerContact &&...
        (270 <= gameData.ballAngle) && (gameData.ballAngle <= 360) % case 6)
      gameData.ballAngle = randi([180, 270]);
      gameData.ballX = gameData.ballX - 1;
      elseif cpuContact &&...
          (90 <= gameData.ballAngle) && (gameData.ballAngle <= 180) % case 7) 
        gameData.ballAngle = randi([0, 90]);
        gameData.ballX = gameData.ballX + 1;
      elseif cpuContact &&... 
          (180 <= gameData.ballAngle) && (gameData.ballAngle <= 270) % case 8)
        gameData.ballAngle = randi([270, 360]);
        gameData.ballX = gameData.ballX + 1;
      elseif playerScored || cpuScored % case 9)
        gameData.ballAngle = randi([0, 360]); 
        gameData.ballX = 0;
        gameData.ballY = 0;
      end
      
      % calculate directional ball velocity
      gameData.ballVelX = gameData.ballVel *...
        cos(deg2rad(360-gameData.ballAngle));
      gameData.ballVelY = gameData.ballVel *...
        -sin(deg2rad(gameData.ballAngle));

    end
    
    % update ball position
    gameData.ballX = gameData.ballX + gameData.ballVelX;
    gameData.ballY = gameData.ballY + gameData.ballVelY;
    
    % update cpu paddle position
    gameData.cpuPaddleY = gameData.ballY * gameData.cpuPaddleCoverage;
    
  end

% create signals that can use the fields of 'gameData' by subscripting
% 'gameData'
ballX = gameData.ballX;
ballY = gameData.ballY;
playerScore = gameData.playerScore.skipRepeats();
cpuScore = gameData.cpuScore.skipRepeats();
cpuPaddleY = gameData.cpuPaddleY;

% define trial end (when a score occurs)
anyScored = playerScore | cpuScore;
events.endTrial = anyScored.then(1);

% define game end (when player or cpu score reaches target score)
endGame = (playerScore == targetScore) | (cpuScore == targetScore);
events.expStop = endGame.then(1).delay(0.1);

% output to the logging display on a score and at game end
scorerName = merge(playerScore.then("Player 1"), cpuScore.then("CPU"));
scoreMsg = @(nm,a,b) sprintf('%s Scores! Player 1: %d CPU: %d', nm, a, b);
outputs.scorecard = anyScored.then(...
  scorerName.mapn(playerScore, cpuScore, scoreMsg));

gameOverMsg = cond(...
  playerScore > cpuScore, 'Game Over! Player 1 Wins!',... 
  cpuScore > playerScore, 'Game Over. cpu Wins :(');
outputs.gameOver = gameOverMsg.at(endGame);

%% Define the visual elements and the experiment parameters

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

% assign the arena, paddles, and ball to the 'visStim' subscriptable signal
% handler
visStim.arena = arena;
visStim.ball = ball;
visStim.playerPaddle = playerPaddle;
visStim.cpuPaddle = cpuPaddle;

% parameters for experimenter in GUI
try
  % 'ballColor' as conditional parameter: on any given trial, the ball
  % color will be chosen at random among three colors: white, red, blue
  p.ballColor = [1 1 1; 1 0 0; 0 0 1]'; % RGB color vector
  p.playerPaddleColor = [1 1 1]'; % RGB color vector
  p.cpuPaddleColor = [1 1 1]'; % RGB color vector
  p.targetScore = 5;
catch
end

end
