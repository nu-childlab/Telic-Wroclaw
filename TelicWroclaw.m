function [] = TelicWroclaw()

%%%%%%FUNCTION DESCRIPTION
%TelicZv1 is a prototype of TelicZ
%It is meant for standalone use
%It is currently incomplete.
%%%%%%%%%%%%%%%%%%%%%%%%%

Screen('Preference', 'SkipSyncTests', 0);
close all;
sca
PsychDefaultSetup(2);
screens = Screen('Screens');
screenNumber = max(screens);
rng('shuffle');
KbName('UnifyKeyNames');



%%%%%%%%
%COLOR PARAMETERS
%%%%%%%%
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white/2;

%%%Screen Stuff

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
%opens a window in the most external screen and colors it)
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
%Anti-aliasing or something? It's from a tutorial
ifi = Screen('GetFlipInterval', window);
%Drawing intervals; used to change the screen to animate the image
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
%The size of the screen window in pixels
[xCenter, yCenter] = RectCenter(windowRect);
%The center of the screen window

%%%%%%
%FINISHED PARAMETERS
%%%%%%

loopTime = .75;

framesPerLoop = round(loopTime / ifi) + 1;

minSpace = 20;
%Current options: 0 or more
%minSpace only affects 'random'; it is the minimum possible number of
%frames between steps

breakTime = .5;
%Current options: 0 or more
%The number of seconds for each pause

crossTime = 1;
%Length of fixation cross time

pauseTime = .5;
%Length of space between loops presentation

textsize = 18;
textspace = 1.5;

rotateLoops = 1;
%Current options: 0 or 1
%1 means each loop is rotated a random number of degrees. 0 means they aren't.

%Matlab's strings are stupid, so I have quotes and quotes with spaces in
%variables here
quote = '''';
squote = ' ''';

%%%%%%
%THE ACTUAL FUNCTION!!!
%%%%%%

%%%%%%%Screen Prep
HideCursor;	% Hide the mouse cursor
Priority(MaxPriority(window));

%%%%%%Shape Prep

theImageLocation = 'star3.png';
[imagename, ~, alpha] = imread(theImageLocation);
imagename(:,:,4) = alpha(:,:);

% Get the size of the image
[s1, s2, ~] = size(imagename);

% Here we check if the image is too big to fit on the screen and abort if
% it is. See ImageRescaleDemo to see how to rescale an image.
if s1 > screenYpixels || s2 > screenYpixels
    disp('ERROR! Image is too big to fit on the screen');
    sca;
    return;
end

% Make the image into a texture
imageTexture = Screen('MakeTexture', window, imagename);





%%%%%%DATA FILES



%%%%%%RUNNING
animateEventLoops(numberOfLoops, framesPerLoop, ...
    minSpace, scale, xCenter, yCenter, window, ...
    pauseTime, brk, breakTime, screenNumber, imageTexture, ...
    ifi, vbl)



%%%%%%Finishing and exiting
sca
Priority(0);
end






%%%%%START/FINISH/BREAK FUNCTIONS%%%%%

function [] = animateEventLoops(numberOfLoops, framesPerLoop, ...
    minSpace, scale, xCenter, yCenter, window, ...
    pauseTime, brk, breakTime, screenNumber, imageTexture, ...
    ifi, vbl)
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white/2;
for loop = numberOfLoops
    %for each number of loops
    points = getPoints(loop, loop * framesPerLoop);
    totalpoints = numel(points)/2;
    Breaks = makeBreaks(brk, totalpoints, loop, framesPerLoop, minSpace);
    xpoints = (points(:, 1) .* scale) + xCenter;
    ypoints = (points(:, 2) .* scale) + yCenter;
    points = [xpoints ypoints];
    
    pt = 1;
    waitframes = 1;
    Screen('FillRect', window, grey);
    Screen('Flip', window);
    while pt <= totalpoints
        if any(pt == Breaks)
            WaitSecs(breakTime);
        end
        
        destRect = [points(pt, 1) - 128/2, ... %left
            points(pt, 2) - 128/2, ... %top
            points(pt, 1) + 128/2, ... %right
            points(pt, 2) + 128/2]; %bottom
        
        % Draw the shape to the screen
        Screen('DrawTexture', window, imageTexture, [], destRect, 0);
        Screen('DrawingFinished', window);
        % Flip to the screen
        vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        pt = pt + 1;
        
    end
    Screen('FillRect', window, black);
    vbl = Screen('Flip', window);
    WaitSecs(pauseTime);
end
end




%%%%%%RESPONSE FUNCTION%%%%%

function [response, time] = getResponse(window, screenXpixels, screenYpixels, textsize, testq)
    black = BlackIndex(window);
    white = WhiteIndex(window);
    textcolor = white;
    xedgeDist = floor(screenXpixels / 3);
    numstep = floor(linspace(xedgeDist, screenXpixels - xedgeDist, 7));
    Screen('TextFont',window,'Arial');
    Screen('TextSize',window,textsize);

    DrawFormattedText(window, testq, 'center', screenYpixels/3, textcolor, 70);
    for x = 1:7
        DrawFormattedText(window, int2str(x), numstep(x), 'center', textcolor, 70);
    end
    DrawFormattedText(window, '  not  \n at all \nsimilar', numstep(1) - (xedgeDist / 25),...
        screenYpixels/2 + 30, textcolor);
    DrawFormattedText(window, 'very \nsimilar', numstep(7) - (xedgeDist / 25), screenYpixels/2 + 30, textcolor);
    Screen('Flip',window);

    % Wait for the user to input something meaningful
    inLoop=true;
    oneseven = [KbName('1!') KbName('2@') KbName('3#') KbName('4$')...
        KbName('5%') KbName('6^') KbName('7&')];
%     numkeys = [89 90 91 92 93 94 95];
    starttime = GetSecs;
    while inLoop
        response = 0;
        [keyIsDown, ~, keyCode]=KbCheck;
        if keyIsDown
            code = find(keyCode);
            if any(code(1) == oneseven)
                endtime = GetSecs;
                response = KbName(code);
                response = response(1);
                if response
                    inLoop=false;
                end
            end
        end
    end
    time = endtime - starttime;
end




%%%%%%FIXATION CROSS FUNCTION%%%%%

function[] = fixCross(xCenter, yCenter, black, window, crossTime)
    fixCrossDimPix = 40;
    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
    allCoords = [xCoords; yCoords];
    lineWidthPix = 4;
    Screen('DrawLines', window, allCoords,...
        lineWidthPix, black, [xCenter yCenter], 2);
    Screen('Flip', window);
    WaitSecs(crossTime);
end




%%%%%%INPUT CHECKING FUNCTIONS%%%%%

function [subj] = subjcheck(subj)
    if ~strncmpi(subj, 's', 1)
        %forgotten s
        subj = ['s', subj];
    end
    if strcmp(subj,'s')
        subj = input(['Please enter a subject ' ...
                'ID:'], 's');
        subj = subjcheck(subj);
    end
    numstrs = ['1'; '2'; '3'; '4'; '5'; '6'; '7'; '8'; '9'; '0'];
    for x = 2:numel(subj)
        if ~any(subj(x) == numstrs)
            subj = input(['Subject ID ' subj ' is invalid. It should ' ...
                'consist of an "s" followed by only numbers. Please use a ' ...
                'different ID:'], 's');
            subj = subjcheck(subj);
            return
        end
    end
    if (exist([subj '.csv'], 'file') == 2) && ~strcmp(subj, 's999')...
            && ~strcmp(subj,'s998')
        temp = input(['Subject ID ' subj ' is already in use. Press y '...
            'to continue writing to this file, or press '...
            'anything else to try a new ID: '], 's');
        if strcmp(temp,'y')
            return
        else
            subj = input(['Please enter a new subject ' ...
                'ID:'], 's');
            subj = subjcheck(subj);
        end
    end
end

function [tel] = telcheck(tel)
    while ~strcmp(tel, 'a') && ~strcmp(tel, 't')
        tel = input('Condition must be a or t. Please enter a or t:', 's');
    end
end

function [list] = listcheck(list)
    if strcmp(list, 'some') || strcmp(list, 'all')
        check = input('some and all are test lists. Type y to continue using a test list.', 's');
        if strcmp(check, 'y')
            return
        end
    end
    while ~strcmp(list, 'blue') && ~strcmp(list, 'pink') && ~strcmp(list, 'green') && ...
            ~strcmp(list, 'orange') && ~strcmp(list, 'yellow')
        list = input('List must be a valid color. Please enter blue, pink, green, orange, or yellow:', 's');
    end
end





%%%%%TRAINING FUNCTIONS%%%%%

function [] = trainSentence1(window, textsize, textspace, sent, screenYpixels)
    Screen('TextFont',window,'Arial');
    Screen('TextSize',window,textsize + 5);
    black = BlackIndex(window);
    white = WhiteIndex(window);
    Screen('FillRect', window, black);
    Screen('Flip', window);
    DrawFormattedText(window, sent, 'center', 'center', white, 70, 0, 0, textspace);
    
    Screen('TextSize',window,textsize);
    DrawFormattedText(window, 'This is the training period for this subpart of the experiment.',...
        'center', screenYpixels/2-70, white, 70, 0, 0, textspace)
    DrawFormattedText(window, 'Ready? Press spacebar.', 'center', screenYpixels/2+50, white, 70, 0, 0, textspace)
    Screen('Flip', window);
    % Wait for keypress
    RestrictKeysForKbCheck(KbName('space'));
    KbStrokeWait;
    Screen('Flip', window);
    RestrictKeysForKbCheck([]);
end

function [] = trainSentence2(window, textsize, textspace, sent, screenYpixels)
    Screen('TextFont',window,'Arial');
    Screen('TextSize',window,textsize + 5);
    black = BlackIndex(window);
    white = WhiteIndex(window);
    Screen('FillRect', window, black);
    Screen('Flip', window);
    DrawFormattedText(window, sent, 'center', 'center', white, 70, 0, 0, textspace);
    
    Screen('TextSize',window,textsize);
    DrawFormattedText(window, 'Ready? Press spacebar.', 'center', screenYpixels/2+50, white, 70, 0, 0, textspace);
    Screen('Flip', window);
    % Wait for keypress
    RestrictKeysForKbCheck(KbName('space'));
    KbStrokeWait;
    Screen('Flip', window);
    RestrictKeysForKbCheck([]);
end

function [] = trainSentence3(window, textsize, textspace, sent, screenYpixels)
    Screen('TextFont',window,'Arial');
    Screen('TextSize',window,textsize + 5);
    black = BlackIndex(window);
    white = WhiteIndex(window);
    Screen('FillRect', window, black);
    Screen('Flip', window);
    DrawFormattedText(window, sent, 'center', 'center', white, 70, 0, 0, textspace);
    
    Screen('TextSize',window,textsize);
    DrawFormattedText(window, 'Ready? Press spacebar.', 'center', screenYpixels/2+50, white, 70, 0, 0, textspace);
    Screen('Flip', window);
    % Wait for keypress
    RestrictKeysForKbCheck(KbName('space'));
    KbStrokeWait;
    Screen('Flip', window);
    RestrictKeysForKbCheck([]);
end

function[] = oneloopobj(window, brk, screenYpixels, xCenter, yCenter, crossTime,...
    loopFrames, minSpace, rotateLoops, displayTime)
    scale = screenYpixels / 15;
    white = WhiteIndex(window);
    black = BlackIndex(window);
    grey = white/2;
    
    
    Screen('FillRect', window, grey);
    Screen('Flip', window);
    fixCross(xCenter, yCenter, black, window, crossTime)
    points = getPoints(3, 3 * loopFrames);
    totalpoints = numel(points)/2;

    Breaks = makeBreaks(brk, totalpoints, 3, loopFrames, minSpace);
    points = rotateGaps(points, totalpoints, loopFrames, Breaks, rotateLoops);
    Breaks = sort(Breaks);

    xpoints = (points(:, 1) .* scale) + xCenter;
    ypoints = (points(:, 2) .* scale) + yCenter;
    points = [xpoints ypoints];

    Screen('FillRect', window, grey);
    Screen('Flip', window);
    for p = 1:Breaks(1)
        if ~any(p == Breaks) && ~any(p+1 == Breaks)
            Screen('DrawLine', window, black, points(p, 1), points(p, 2), ...
                points(p+1, 1), points(p+1, 2), 5);
        end
    end
    Screen('DrawingFinished', window);
    %t1 = GetSecs;
    vbl = Screen('Flip', window);
    %puts the image on the screen
    Screen('FillRect', window, black);
    WaitSecs(displayTime);
    vbl = Screen('Flip', window);
    %blanks the screen
end

function[] = twoloopobj(window, brk, screenYpixels, xCenter, yCenter, crossTime,...
    loopFrames, minSpace, rotateLoops, displayTime)
    scale = screenYpixels / 15;
    white = WhiteIndex(window);
    black = BlackIndex(window);
    grey = white/2;
    
    
    Screen('FillRect', window, grey);
    Screen('Flip', window);
    fixCross(xCenter, yCenter, black, window, crossTime)
    points = getPoints(3, 3 * loopFrames);
    totalpoints = numel(points)/2;

    Breaks = makeBreaks(brk, totalpoints, 3, loopFrames, minSpace);
    points = rotateGaps(points, totalpoints, loopFrames, Breaks, rotateLoops);
    Breaks = sort(Breaks);

    xpoints = (points(:, 1) .* scale) + xCenter;
    ypoints = (points(:, 2) .* scale) + yCenter;
    points = [xpoints ypoints];

    Screen('FillRect', window, grey);
    Screen('Flip', window);
    for p = 1:Breaks(2)
        if ~any(p == Breaks) && ~any(p+1 == Breaks)
            Screen('DrawLine', window, black, points(p, 1), points(p, 2), ...
                points(p+1, 1), points(p+1, 2), 5);
        end
    end
    Screen('DrawingFinished', window);
    %t1 = GetSecs;
    vbl = Screen('Flip', window);
    %puts the image on the screen
    Screen('FillRect', window, black);
    WaitSecs(displayTime);
    vbl = Screen('Flip', window);
    %blanks the screen
end

function[] = oneloopev(window, brk, screenYpixels, xCenter, yCenter, crossTime,...
    loopFrames, minSpace, ifi, imageTexture, vbl, breakTime)
    scale = screenYpixels / 8;
    white = WhiteIndex(window);
    black = BlackIndex(window);
    grey = white/2;


    Screen('FillRect', window, grey);
    Screen('Flip', window);
    fixCross(xCenter, yCenter, black, window, crossTime)
    
    points = getPoints(3, 3 * loopFrames);
    totalpoints = numel(points)/2;
    Breaks = makeBreaks(brk, totalpoints, 3, loopFrames, minSpace);
    xpoints = (points(:, 1) .* scale) + xCenter;
    ypoints = (points(:, 2) .* scale) + yCenter;
    points = [xpoints ypoints];
    Breaks = sort(Breaks);
    
    pt = 1;
    waitframes = 1;
    %t1 = GetSecs;
    Screen('FillRect', window, grey);
    Screen('Flip', window);
    while pt <= Breaks(1)
        if any(pt == Breaks)
            WaitSecs(breakTime);
        end
        
        destRect = [points(pt, 1) - 128/2, ... %left
            points(pt, 2) - 128/2, ... %top
            points(pt, 1) + 128/2, ... %right
            points(pt, 2) + 128/2]; %bottom
        
        % Draw the shape to the screen
        Screen('DrawTexture', window, imageTexture, [], destRect, 0);
        Screen('DrawingFinished', window);
        % Flip to the screen
        vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        pt = pt + 1;
        
    end
end

function[] = twoloopev(window, brk, screenYpixels, xCenter, yCenter, crossTime,...
    loopFrames, minSpace, ifi, imageTexture, vbl, breakTime)
    scale = screenYpixels / 8;
    white = WhiteIndex(window);
    black = BlackIndex(window);
    grey = white/2;


    Screen('FillRect', window, grey);
    Screen('Flip', window);
    fixCross(xCenter, yCenter, black, window, crossTime)
    
    points = getPoints(3, 3 * loopFrames);
    totalpoints = numel(points)/2;
    Breaks = makeBreaks(brk, totalpoints, 3, loopFrames, minSpace);
    xpoints = (points(:, 1) .* scale) + xCenter;
    ypoints = (points(:, 2) .* scale) + yCenter;
    points = [xpoints ypoints];
    Breaks = sort(Breaks);
    
    pt = 1;
    waitframes = 1;
    %t1 = GetSecs;
    Screen('FillRect', window, grey);
    Screen('Flip', window);
    while pt <= Breaks(2)
        if any(pt == Breaks)
            WaitSecs(breakTime);
        end
        
        destRect = [points(pt, 1) - 128/2, ... %left
            points(pt, 2) - 128/2, ... %top
            points(pt, 1) + 128/2, ... %right
            points(pt, 2) + 128/2]; %bottom
        
        % Draw the shape to the screen
        Screen('DrawTexture', window, imageTexture, [], destRect, 0);
        Screen('DrawingFinished', window);
        % Flip to the screen
        vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        pt = pt + 1;
        
    end
end

function [] = endTraining(window, textsize, textspace, trainend, testq, screenYpixels)
    Screen('TextFont',window,'Arial');
    Screen('TextSize',window,textsize+5);
    black = BlackIndex(window);
    white = WhiteIndex(window);
    Screen('FillRect', window, black);
    Screen('Flip', window);
    textcolor = white;
    DrawFormattedText(window, testq, 'center', 'center',...
        textcolor, 70, 0, 0, textspace);
    
    Screen('TextSize',window,textsize);
    DrawFormattedText(window, trainend, 'center', screenYpixels/2-220,...
        textcolor, 70, 0, 0, textspace);
    DrawFormattedText(window, 'Ready? Press spacebar.', 'center', screenYpixels/2+40,...
        textcolor, 70, 0, 0, textspace);
    
    Screen('Flip', window);
    % Wait for keypress
    RestrictKeysForKbCheck(KbName('space'));
    KbStrokeWait;
    Screen('Flip', window);
    RestrictKeysForKbCheck([]);
end






%%%%%STIMULUS MATH FUNCTIONS%%%%%


function [points] = getPoints(loops, steps)
    start = pi/loops;
    theta = linspace(start, start + 2*pi, steps);
    thetalist = reshape(theta, [numel(theta), 1]);
    rholist = zeros([numel(theta), 1]);
    for m = 1:numel(theta)
        rholist(m, 1) = 1 + cos(loops*thetalist(m, 1));
    end
    %Creates two arrays; theta and rho. Theta defines the intervals and
    %distance around the circle, while rho looks at the amplitude.

    points = zeros([numel(theta), 2]);


    for m = 1:numel(theta)
        points(m, 1) = rholist(m, 1)*cos(thetalist(m, 1));
        points(m, 2) = rholist(m, 1)*sin(thetalist(m, 1));
    end

    %The polar coordinates from theta and rho are translated into Cartesian
    %coordinates. For a brief explanation, see
    %https://www.mathsisfun.com/polar-cartesian-coordinates.html
end

function [Breaks] = makeBreaks(breakType, totalpoints, loops, loopFrames, minSpace)
    if strcmp(breakType, 'equal')
        Breaks = int16(linspace(loopFrames, totalpoints, loops));

    elseif strcmp(breakType, 'random')
        Breaks = randi([1 (loops*loopFrames)], 1, loops-1);
        x = 1;
        y = 2;
        while x <= numel(Breaks)
            while y <= numel(Breaks)
                if x ~= y && abs(Breaks(x) - Breaks(y)) < minSpace || Breaks(x) < minSpace ||...
                        (loops*loopFrames) - Breaks(x) < minSpace
                    Breaks(x) =  randi([1, (loops*loopFrames)], 1, 1);
                    x = 1;
                    y = 0;
                end
                y = y + 1;
            end
            x = x + 1;
            y = 1;
        end

    else
        Breaks = [];
    end
end


function [rpoints] = rotateGaps(points, totalpoints, loopFrames, Breaks, rotateLoops)
    petalnum = 0;
    rpoints = points;
    halfLoop = floor(loopFrames / 2);

    %move to origin
    for m = 1:totalpoints-1 
        if any(m == Breaks)
            petalnum = petalnum + 1;
        end
        rpoints(m, 1) = points(m, 1) - points(halfLoop + (loopFrames * petalnum), 1) / 2;
        rpoints(m, 2) = points(m, 2) - points(halfLoop + (loopFrames * petalnum), 2) / 2;
    end  

    nrpoints = rpoints;
    f = randi(360);

    if rotateLoops
        %rotate (not transform-dependent)
        for m = 1:totalpoints-1
            if any(m == Breaks)
                f = randi(360);
            end 
            rpoints(m, 1) = nrpoints(m, 1)*cos(f) - nrpoints(m, 2)*sin(f);
            rpoints(m, 2) = nrpoints(m, 2)*cos(f) + nrpoints(m, 1)*sin(f);
        end
    end

    nrpoints = rpoints;
    petalnum = 0;

    %push based on new tip direction.
    for m = 1:totalpoints-1
        if any(m == Breaks)
            petalnum = petalnum + 1;
        end
        rpoints(m, 1) = nrpoints(m, 1) + (points(halfLoop + (loopFrames * petalnum), 1) *2);
        rpoints(m, 2) = nrpoints(m, 2) + (points(halfLoop + (loopFrames * petalnum), 2) *2);
    end
end