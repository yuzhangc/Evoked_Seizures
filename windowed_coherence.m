function [output_val] = windowed_coherence(input_data, fs, winLen, winDisp)

% On-Demand Seizures Facilitate Rapid Screening of Therapeutics for Epilepsy
% Authors: Yuzhang Chen, Brian Litt, Flavia Vitale, Hajime Takano
% DOI: https://doi.org/10.7554/eLife.101859

% Function Purpose: Calculate average coherence across all frequency space

% Input Variables
% input_data - data for calculation.
% fs - sampling rate
% winLen - window length
% winDisp - window Displacement

% Output Variables
% output_val - calculated mean coherence across all frequencies

% -------------------------------------------------------------------------

% Determine number of windows
NumWins = floor(size(input_data,1)/fs/winDisp - (winLen-winDisp)/winDisp);
    
% Defining start and stop for each window. For first window, start at beginning
% and go to the length of winLen.
winst = 1;
winend = winLen * fs;
    
% Loops through all windows
for winnum = 1:NumWins
    
    if size(input_data,2) == 4
    % Coherence Between Screws
    coher_temp(winnum,1) = mean(mscohere(input_data(winst:winend,1),input_data(winst:winend,2),100,2,[],fs));
    % Coherence Between Wires
    coher_temp(winnum,2) = mean(mscohere(input_data(winst:winend,3),input_data(winst:winend,4),100,2,[],fs));
    % Coherence Between Ipsilateral (Screw + Wire)
    coher_temp(winnum,3) = mean(mscohere(input_data(winst:winend,1),input_data(winst:winend,3),100,2,[],fs));
    % Coherence Between Contralateral (Screw + Wire)
    coher_temp(winnum,4) = mean(mscohere(input_data(winst:winend,1),input_data(winst:winend,4),100,2,[],fs));
    
    elseif size(input_data,2) == 3
    % Coherence Between Ch 1 and 2
    coher_temp(winnum,1) = mean(mscohere(input_data(winst:winend,1),input_data(winst:winend,2),100,2,[],fs));
    % Coherence Between Ch 1 and 3
    coher_temp(winnum,2) = mean(mscohere(input_data(winst:winend,1),input_data(winst:winend,3),100,2,[],fs));
    % Coherence Between Ch 2 and 3
    coher_temp(winnum,3) = mean(mscohere(input_data(winst:winend,2),input_data(winst:winend,3),100,2,[],fs));
    
    elseif size(input_data,2) == 2    
    % Coherence Between Screws Ch 1 and Ch 2
    coher_temp(winnum,1) = mean(mscohere(input_data(winst:winend,1),input_data(winst:winend,2),100,2,[],fs));
    
    end
    
    % Move window forward by winDisp
    winst = winst + winDisp * fs;
    winend = winst - 1 + winLen * fs;
    
end

output_val = coher_temp;

end