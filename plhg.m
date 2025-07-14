function [output_val] = plhg(input_data, fs)

% On-Demand Seizures Facilitate Rapid Screening of Therapeutics for Epilepsy
% Authors: Yuzhang Chen, Brian Litt, Flavia Vitale, Hajime Takano
% DOI: https://doi.org/10.7554/eLife.101859

% Calculate Phase locked High Gamma.

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

% Step 3: Calculate the LFP phase and the high gamma amplitude phase

% LFP Phase
tophase_low = hilbert(lowfreq);
IMAGS = imag(tophase_low);
REALS = real(tophase_low);
lowphase = atan2(IMAGS,REALS);
clear IMAGS REALS

% High Gamma Amplitude
tophase_high = hilbert(highfreq);
highamp = abs(tophase_high); 

% High Gamma Amplitude Phase
tophase_highamp = hilbert(highamp);
IMAGS = imag(tophase_highamp);
REALS = real(tophase_highamp);
highampphase = atan2(IMAGS,REALS);
clear IMAGS REALS

% Step 4: Calculates Phase Locked High Gamma
output_val = abs(mean(highamp.* exp(1i *(lowphase - highampphase))));

end