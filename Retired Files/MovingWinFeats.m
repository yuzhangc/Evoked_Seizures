function featval = MovingWinFeats  (x, fs, winLen, winDisp, featFn, varargs)

% MovingWinFeats - Calculates Features Across a Moving Window
% Output
% featval - column based calculations for the feature featFn with input
% value x
% Input
% x - data to be analyzed
% fs - sampling rate
% winLen - length of window (in seconds)
% winDisp - displacement of window (in seconds)
% featFn - Feature Function

% Number of Windows
NumWins = floor(size(x,1)/fs/winDisp - (winLen-winDisp)/winDisp);
featval = [];

% Loops Until All Windows Have Been Covered
for ch = 1:size(x,2)
    % Defining Variables
    winst = 1;
    winend = winLen * fs;
    for winnum = 1:NumWins
        window = x(winst:winend,ch);
        if isempty(varargs)
        featval(winnum,ch) = featFn(window);
        elseif length(varargs) == length(x)
            window2 = varargs(winst:winend,ch);
            featval(winnum,:) = featFn(window,window2);
        else
        featval(winnum,ch) = featFn(window,varargs);
        end
        winst = winst + winDisp * fs;
        winend = winst - 1 + winLen * fs;
    end
end

end