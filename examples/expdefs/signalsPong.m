function signalsPong(t, events, pars, visStim, inputs, outputs, audio)
% This is a working example of pong in signals
% To be run via ExpTestPanel GUI (exp.ExpTest)
% 170328 - AP 

%% Define constants for the World 

% Paddle parameters
paddleInitialY = 0; % initial height of paddle
playerPaddleX = 160; % near right edge of screen 
computerPaddleX = -160; % near left edge of screen
paddleSz = [10,50]; % size in pixels
playerPaddle = vis.patch(t,'rectangle');
computerPaddle = vis.patch(t,'rectangle');
computerPaddleVel = 3; % paddle velocity in y-direction

% Ball parameters
ballSz = [5,5]; % size in pixels
ballInitialY = 0;
ballInitialX = 0;
ballVelX = 3; % ball velocity in x-direction
ballVelY = 3; % ball velocity in y-direction
ball = vis.patch(t, 'circle');

% Game parameters
% Create a struct with "game data", and create a subscriptable signal
% from that struct which will be used to keep track of the game
gameDataInitial.ballPos = [ballInitialX ballInitialY];
gameDataInitial.ballVel = [ballVelX ballVelY];
gameDataInitial.computerPaddlePos = [computerPaddleX paddleInitialY];
gameDataInitial.computerPaddleVel = computerPaddleVel;
gameDataInitial.playerPaddlePos = [playerPaddleX paddleInitialY];
gameDataInitial.paddleSz = paddleSz;

% Mouse parameters
% Get the initial value of the y-position of the mouse when the experiment
% starts. The y-position of the mouse will be used to control the paddle

  function yPos = getYPos()
    % GETYPOS uses PTB's 'GetMouse' function to return the mouse y-coordinate,
    % in pixels
    [~, yPos] = GetMouse();
  end

mouseInitialY = events.expStart.map(true).map(@(~) getYPos);
cursorGain = 0.33; % set gain for cursor
%% Render the states (via helper functions)
% A state is a number - the time elapsed from experiment start, given by 
% 't', which we modify to 'tUpdate' for sake of limiting computational load

updateTime = 0.01; % how often to update, in s
tUpdateMod = t - mod(t, updateTime);
tUpdate = tUpdateMod.skipRepeats;

wheel = inputs.wheel; % get signal for wheel

% get y-value player's paddle updates to when moving the mouse
playerPaddleYUpdateVal =... 
  (wheel.map(@(~) getYPos) - mouseInitialY) * cursorGain;
% make sure the y-value of the player's paddle is within the screen bounds
playerPaddleY = cond(playerPaddleYUpdateVal > 90, 90,...
  playerPaddleYUpdateVal < -90, -90, true, playerPaddleYUpdateVal);

% create a function to run the game (update the world: state -> state)

  function gameData = runGame(gameData)
    % Define the border along the top: reverse ball altitude velocity
    if abs(gameData.ball_position(2)) >= 90
      gameData.ball_velocity(2) = -gameData.ball_velocity(2);
    end
    
    % Define the boundaries where the ball should bounce or score
    if abs(gameData.ball_position(1)) >= 180
      
      % Reset the ball if it reaches the edge of the board
      gameData.ball_position = [0,0];
      gameData.ball_velocity = sign(rand(1,2) - 0.5).*[3,rand*3];
      
    elseif ...
        (gameData.ball_position(1) <= gameData.computer_paddle_position(1) && ...
        gameData.ball_position(2) <= gameData.computer_paddle_position(2)+(gameData.paddle_size(2)/2) && ...
        gameData.ball_position(2) >= gameData.computer_paddle_position(2)-(gameData.paddle_size(2)/2)) || ...
        (gameData.ball_position(1) >= gameData.player_paddle_azimuth && ...
        gameData.ball_position(2) <= player_paddle_altitude+(gameData.paddle_size(2)/2) && ...
        gameData.ball_position(2) >= player_paddle_altitude-(gameData.paddle_size(2)/2))
      
      % Reverse ball azimuth velocity when it hits a paddle
      gameData.ball_velocity(1) = -gameData.ball_velocity(1);
      
    end
    % Update the ball position
    gameData.ball_position = gameData.ball_position + gameData.ball_velocity;
    
    % Update the computer paddle altitude
    gameData.computer_paddle_position(2) = gameData.computer_paddle_position(2) + ...
      gameData.computer_paddle_speed*sign(gameData.ball_position(2) - gameData.computer_paddle_position(2));
    
  end


%% Set up update clock
% Set updates for every 10 ms



%%%% PADDLE PARAMETERS

%%%% PLAYER PADDLE
player_paddle_altitude = wheel.delta.scan(@setPlayerPaddle,...
  paddleInitialY);

playerPaddle = vis.patch(t,'rectangle');
playerPaddle.azimuth = playerPaddleX;
playerPaddle.altitude = cond( ...
    events.expStart,player_paddle_altitude, ...
    true, 0);
playerPaddle.dims = paddleSz;
playerPaddle.show = true;

%%%% COMPUTER POSITIONS
% Need to group ball and paddle because they are co-dependent: this means
% that they need to be updated simultaneously. Set up a structure with all
% the computer parameters that will be updated
game_data_initial.ball_position = [0,0];
game_data_initial.ball_velocity = sign(rand(1,2) - 0.5).*[3,rand*3];
game_data_initial.computer_paddle_position = [computerPaddleX,paddleInitialY];
game_data_initial.computer_paddle_speed = 2;
game_data_initial.player_paddle_azimuth = playerPaddleX;
game_data_initial.paddle_size = paddleSz;
% Feed in the player paddle altitude to the scan: this way the computer
% always knows where the player paddle is and can use it as a value instead
% of a signal, which makes things a lot easier
game_data = player_paddle_altitude.at(tUpdate).scan(@runGame,game_data_initial).subscriptable;

%%%% BALL
ballSz = [5,5];

ball = vis.patch(t,'rectangle');
ball.azimuth = game_data.ball_position(1);
ball.altitude = game_data.ball_position(2);
ball.dims = ballSz;
ball.show = true;

%%%% COMPUTER PADDLE
computerPaddle = vis.patch(t,'rectangle');
computerPaddle.azimuth = computerPaddleX;
computerPaddle.altitude = game_data.computer_paddle_position(2);
computerPaddle.dims = paddleSz;
computerPaddle.show = true;

%%%% SEND VISUAL COMPONENTS TO STIM HANDLER
visStim.player_paddle = playerPaddle;
visStim.computer_paddle = computerPaddle;
visStim.ball = ball;

%% Define events to save

events.endTrial = events.newTrial.delay(5);

end

%% helper functions

function playerPaddleY = paddleBoundary(playerPaddleY, wheel)

% Update the position of the paddle, unless is it at the edge of the board,
% in which case set the position as the edge.
playerPaddleY = playerPaddleY + wheel;
if playerPaddleY > 90
    playerPaddleY = 90;
elseif playerPaddleY < -90
    playerPaddleY = -90;
end

end

function game_data = update_game_data(game_data,player_paddle_altitude)

% Define the border along the top: reverse ball altitude velocity
if abs(game_data.ball_position(2)) >= 90
    game_data.ball_velocity(2) = -game_data.ball_velocity(2);
end

% Define the boundaries where the ball should bounce or score
if abs(game_data.ball_position(1)) >= 180
    
    % Reset the ball if it reaches the edge of the board
    game_data.ball_position = [0,0];
    game_data.ball_velocity = sign(rand(1,2) - 0.5).*[3,rand*3];
    
elseif ...
        (game_data.ball_position(1) <= game_data.computer_paddle_position(1) && ...
        game_data.ball_position(2) <= game_data.computer_paddle_position(2)+(game_data.paddle_size(2)/2) && ...
        game_data.ball_position(2) >= game_data.computer_paddle_position(2)-(game_data.paddle_size(2)/2)) || ...
        (game_data.ball_position(1) >= game_data.player_paddle_azimuth && ...
        game_data.ball_position(2) <= player_paddle_altitude+(game_data.paddle_size(2)/2) && ...
        game_data.ball_position(2) >= player_paddle_altitude-(game_data.paddle_size(2)/2))
    
    % Reverse ball azimuth velocity when it hits a paddle
    game_data.ball_velocity(1) = -game_data.ball_velocity(1);
    
end

% Update the ball position
game_data.ball_position = game_data.ball_position + game_data.ball_velocity;

% Update the computer paddle altitude
game_data.computer_paddle_position(2) = game_data.computer_paddle_position(2) + ...
    game_data.computer_paddle_speed*sign(game_data.ball_position(2) - game_data.computer_paddle_position(2));

end











