clear all

% Loads Files

load('G:\Clone of ORG_YZ 20230710\20230813_2_44_KA_Thy1_SST_Arch\Filtered Seizure Data.mat')

% Read Seizure Parameters

sz_parameters = readmatrix(strcat('G:\Clone of ORG_YZ 20230710\20230813_2_44_KA_Thy1_SST_Arch\','Trials Spreadsheet.csv'));

% Model Seizure is 24 - one stim and 28 - 2 stim

model_seizure_24 = output_data{3};

%% Continuous Wavelet Transform

figure;

subplot(4,1,1)

% Continuous (Morse) Wavelet Transform of Model Seizure

[cfs,frq] = cwt(model_seizure_24(:,1),"morse",fs);

% Vector representing the sample times.

tms = (0:numel(model_seizure_24(:,1))-1)/fs;

% Plot
surface(tms,frq,abs(cfs))
axis tight
shading flat

% Colorbar Limit
clim([0,3])
% Frequency Limit
ylim([1,100])
% Time Limit (in seconds)
xlim([0,120])

% Labels
xlabel("Time (s)")
ylabel("Frequency (Hz)")
title("Morse Wavelet")

subplot(4,1,2)

% Continuous (Bump) Wavelet Transform of Model Seizure

[cfs,frq] = cwt(model_seizure_24(:,1),"bump",fs);

% Plot
surface(tms,frq,abs(cfs))
axis tight
shading flat

% Colorbar Limit
clim([0,3])
% Frequency Limit
ylim([1,100])
% Time Limit (in seconds)
xlim([0,120])

% Labels
xlabel("Time (s)")
ylabel("Frequency (Hz)")
title("Bump Wavelet")

subplot(4,1,3)

% Plot
pspectrum(model_seizure_24(:,1),fs,"spectrogram","TimeResolution",0.2);

colorbar hide

% Colorbar Limit
clim([0,10])
% Frequency Limit
ylim([0.001,0.1])
% Time Limit (in minutes)
xlim([0,2])

% Labels
xlabel("Time (min)")
ylabel("Frequency (kHz)")
title("Fourier Transform Spectrogram")

% Regular Fourier Spectrogram

subplot(4,1,4)

plot(tms,model_seizure_24(:,1))

% Labels
xlim([0,120])
xlabel("Time (s)")
ylabel("Filtered Signal")
title("Raw Signal")

% 3D Scalogram

helperPlotScalogram3d(model_seizure_24(:,1),fs)

%% Discrete Wavelet Transform

t = (0:numel(model_seizure_24(:,1))-1)/fs;

mra = modwtmra(modwt(model_seizure_24(:,1),8));
helperMRAPlot(model_seizure_24(:,1),mra,t,'wavelet','Wavelet MRA')

[imf_emd,resid_emd] = emd(model_seizure_24(:,1));
helperMRAPlot(model_seizure_24(:,1),imf_emd,t,'emd','Empirical Mode Decomposition')

[imf_vmd,resid_vmd] = vmd(model_seizure_24(:,1));
helperMRAPlot(model_seizure_24(:,1),imf_vmd,t,'vmd','Variational Mode Decomposition')

%% Signal Reconstruction In Wavelets