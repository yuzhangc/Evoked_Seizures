function [output_val] = plhg(input_data, fs)

% Calculate selected features on data. Note feature 10 is specific to 4
% channel recordings.

% Input Variables
% input_data - data for calculation.
% fs - sampling rate

% Output Variables
% output_val - calculated phase locked high gamma value

% -------------------------------------------------------------------------

% Step 1: Generate filter to get low (4-30 Hz) and high gamma (80-150 Hz) signals

[low_num,low_denom] = butter(2,[4 30]/(fs/2),'bandpass');
[hg_num,hg_denom] = butter(2,[80 150]/(fs/2),'bandpass');

% Step 2: Filter input_data with no phase shift

lowfreq = filtfilt(low_num,low_denom,input_data);
highfreq = filtfilt(hg_num,hg_denom,input_data);

% Step 3: Calculate the LFP phase and the high gamma amplitude

tophase_low = hilbert(lowfreq);
IMAGS = imag(tophase_low);
REALS = real(tophase_low);
lowphase = atan2(IMAGS,REALS);
clear IMAGS REALS

tophase_high = hilbert(highfreq);
IMAGS = imag(tophase_high);
REALS = real(tophase_high);
highamp = sqrt(IMAGS.^2 + REALS.^2);    
clear IMAGS REALS

% Step 4: Calculates Phase Locked High Gamma
output_val = abs(mean(abs(tophase_high) .* exp(1i *(lowphase - highamp))));

end