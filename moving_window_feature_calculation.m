function featval = moving_window_feature_calculation  (input_data, fs, winLen, winDisp, featFn, varargs)

% On-Demand Seizures Facilitate Rapid Screening of Therapeutics for Epilepsy
% Authors: Yuzhang Chen, Brian Litt, Flavia Vitale, Hajime Takano
% DOI: https://doi.org/10.7554/eLife.101859

% Function Purpose Calculate features along a moving window with certain displacement.

% Input Variables
% input_data - EEG data
% fs - sampling rate
% winLen - window length (seconds)
% winDisp - window displacement (seconds)
% featFn - feature function @feature_function
% varargs - optional arguments for featFn

% Output Variables
% featval - calculated features across windows

% -------------------------------------------------------------------------

% Determine number of windows and reset featval
NumWins = floor(size(input_data,1)/fs/winDisp - (winLen-winDisp)/winDisp);
featval = [];

% Loops through all channels
for ch = 1:size(input_data,2)
    
    % Defining start and stop for each window. For first window, start at
    % beginning and go to the length of winLen.
    winst = 1;
    winend = winLen * fs;
    
    % Loops through all windows
    for winnum = 1:NumWins
        
        % Extracts data from window for that particular channel
        window = input_data(winst:winend,ch);
        
        % ----------------------------------------------------------------
        
        % If no additional arguments are presented, directly calculate
        % feature value
        if isempty(varargs)
        featval(winnum,ch) = featFn(window);
        
        % ----------------------------------------------------------------
        
        % Otherwise feed in arguments into function
        else
        featval(winnum,ch) = featFn(window,varargs{:});
        end
        
        % ----------------------------------------------------------------
        
        % Move window forward by winDisp
        winst = winst + winDisp * fs;
        winend = winst - 1 + winLen * fs;
        
    end
end

end