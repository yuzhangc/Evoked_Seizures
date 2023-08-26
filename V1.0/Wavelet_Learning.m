clear all

% Loads Files

load('G:\Clone of ORG_YZ 20230710\20230624_37_KA_THY\Filtered Seizure Data.mat')

% Read Seizure Parameters

sz_parameters = readmatrix(strcat(path_extract,'Trials Spreadsheet.csv'));

% Model Seizure is 24 - one stim and 28 - 2 stim

model_seizure_24 = output_data{24};
model_seizure_28 = output_data{28};

%% Continuous Wavelet Transform

figure;

subplot(3,1,1)

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
xlim([0,60])

% Labels
xlabel("Time (s)")
ylabel("Frequency (Hz)")

subplot(3,1,2)

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
xlim([0,60])

% Labels
xlabel("Time (s)")
ylabel("Frequency (Hz)")

subplot(3,1,3)

plot(tms,model_seizure_24(:,1))

% Labels
xlim([0,60])
xlabel("Time (s)")
ylabel("Filtered Signal")

% 3D Scalogram

figure;

helperPlotScalogram3d(model_seizure_24(:,1),fs)

%% Discrete Wavelet Transform

t = (0:numel(model_seizure_24(:,1))-1)/fs;

mra = modwtmra(modwt(model_seizure_24(:,1),8));
helperMRAPlot(model_seizure_24(:,1),mra,t,'wavelet','Wavelet MRA')

[imf_emd,resid_emd] = emd(model_seizure_24(:,1));
helperMRAPlot(model_seizure_24(:,1),imf_emd,t,'emd','Empirical Mode Decomposition')

[imf_vmd,resid_vmd] = vmd(model_seizure_24(:,1));
helperMRAPlot(model_seizure_24(:,1),imf_vmd,t,'vmd','Variational Mode Decomposition')