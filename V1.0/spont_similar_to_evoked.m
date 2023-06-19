% Import E:\Awake EEG\Spontaneous TEXT Files\4_28_12H24M_1_Cage2_155324
% Manually

% spont_all = table2array(H24M1Cage2155324(:,2:5));
% sz_start = 126367;

% spont_all = table2array(H24M1Cage2185924(:,2:5));
% sz_start = 125310;

% spont_all = table2array(H24M1Cage4090424(:,2:5));
% sz_start = 124453;

spont_all = table2array(h03m(:,2:6));
sz_start = find(spont_all(:,5) > 2000);
spont_all = spont_all(:,1:4);

%%

fs_EEG = 2000;
t_before_EEG = 5;
plot_duration = 80;

spont_look_like = spont_all(sz_start - t_before_EEG * fs_EEG:end,:);

figure
subplot(2,3,1:3)
norm_factor = max(abs(spont_all));
for k = 1:size(spont_look_like,2)
    hold on
    plot(1/fs_EEG:1/fs_EEG:plot_duration+t_before_EEG,...
        spont_look_like(1:(t_before_EEG+plot_duration)*fs_EEG,k)...
        ./norm_factor(k)+(k-1)*1,'Color','k')
    hold off
    ylim([-1,k])
    xlim([0,t_before_EEG+plot_duration])
    xlabel('Time (sec)')
end

subplot(2,3,4)
for k = 1:size(spont_look_like,2)
    hold on
    plot(1/fs_EEG:1/fs_EEG:plot_duration+t_before_EEG,...
        spont_look_like(1:(t_before_EEG+plot_duration)*fs_EEG,k)...
        ./norm_factor(k)+(k-1)*1,'Color','k')
    hold off
    ylim([-1,k])
    xlim([5,15])
    xlabel('Time (sec)')
end

subplot(2,3,5)
for k = 1:size(spont_look_like,2)
    hold on
    plot(1/fs_EEG:1/fs_EEG:plot_duration+t_before_EEG,...
        spont_look_like(1:(t_before_EEG+plot_duration)*fs_EEG,k)...
        ./norm_factor(k)+(k-1)*1,'Color','k')
    hold off
    ylim([-1,k])
    xlim([18,28])
    xlabel('Time (sec)')
end

subplot(2,3,6)
for k = 1:size(spont_look_like,2)
    hold on
    plot(1/fs_EEG:1/fs_EEG:plot_duration+t_before_EEG,...
        spont_look_like(1:(t_before_EEG+plot_duration)*fs_EEG,k)...
        ./norm_factor(k)+(k-1)*1,'Color','k')
    hold off
    ylim([-1,k])
    xlim([38,48])
    xlabel('Time (sec)')
end

set(gcf,'Position', [294 671.5000 1583 307.5000])

%% Feature Plot

spont_all = spont_look_like(1:60*fs_EEG,:);

% Line Length
LLFn = @(x) sum(abs(diff(x)));
% Area
Area = @(x) sum(abs(x));
% Energy
Energy = @(x)  sum(x.^2);
% Zero Crossing Around Mean
ZeroCrossing = @(x) sum((x(2:end) - mean(x) > 0 & x(1:end-1) - mean(x) < 0))...
    + sum((x(2:end) - mean(x) < 0 & x(1:end-1) - mean(x) > 0));

% RMS Mean
RMS_evoked = MovingWinFeats(spont_all, fs_EEG, winLen, winDisp, @rms,[]);
norm_RMS_evoked = (RMS_evoked - mean(RMS_evoked))./std(RMS_evoked);
% Skewness
Skew_evoked = MovingWinFeats(spont_all, fs_EEG, winLen, winDisp, @skewness,[]);
norm_Skew_evoked = (Skew_evoked - mean(Skew_evoked))./std(Skew_evoked);
% Approximate Entropy
['Entropy']
AEntropy_evoked = MovingWinFeats(spont_all, fs_EEG, winLen, winDisp, @approximateEntropy,[]);
norm_AEntropy_evoked = (AEntropy_evoked - mean(AEntropy_evoked))./std(AEntropy_evoked);
['Done']
% Line Length
LLFn_evoked = MovingWinFeats(spont_all, fs_EEG, winLen, winDisp, LLFn,[]);
norm_LLFn_evoked = (LLFn_evoked - mean(LLFn_evoked))./std(LLFn_evoked);
% Area
Area_evoked = MovingWinFeats(spont_all, fs_EEG, winLen, winDisp, Area,[]);
norm_Area_evoked = (Area_evoked - mean(Area_evoked))./std(Area_evoked);
% Energy
Energy_evoked = MovingWinFeats(spont_all, fs_EEG, winLen, winDisp, Energy,[]);
norm_Energy_evoked = (Energy_evoked - mean(Energy_evoked))./std(Energy_evoked);
% Zero Crossing
Zero_Crossing_evoked = MovingWinFeats(spont_all, fs_EEG, winLen, winDisp, ZeroCrossing,[]);
norm_Zero_Crossing_evoked = (Zero_Crossing_evoked - mean(Zero_Crossing_evoked))./std(Zero_Crossing_evoked);
['LP']
% Lyapunov Exponent
LP_exp_evoked = MovingWinFeats(spont_all, fs_EEG, winLen, winDisp, @lyapunovExponent,fs_EEG);
norm_LP_exp_evoked = (LP_exp_evoked - mean(LP_exp_evoked))./std(LP_exp_evoked);

%% PLHG
    
    % Filter to generate low (4-30 Hz) and high gamma (80-150 Hz) signals
    % create LFP and HG filters
    [low_num,low_denom] = butter(2,[4 30]/(2000/2),'bandpass');
    [hg_num,hg_denom] = butter(2,[80 150]/(2000/2),'bandpass');
    
   
    % filter all channels 
    lowfreq = filtfilt(low_num,low_denom,spont_all);
    highfreq = filtfilt(hg_num,hg_denom,spont_all);
    
    % Calculate the LFP phase and the HG amplitude
    tophase_low = hilbert(lowfreq);
    IMAGS = imag(tophase_low);
    REALS = real(tophase_low);
    lowphase = atan2(IMAGS,REALS);
    clear IMAGS REALS
    
    tophase_high = hilbert(highfreq);
    IMAGS = imag(tophase_high);
    REALS = real(tophase_high);
    % highphase = atan2(IMAGS,REALS);
    highamp = sqrt(IMAGS.^2 + REALS.^2);    
    clear IMAGS REALS
    
    % Windows
    NumWins = floor(size(spont_all,1)/fs_EEG/winDisp - (winLen-winDisp)/winDisp);
    plhg_temp = [];
    
    % Defining Lengths
    winst = 1;
    winend = winLen * fs_EEG;
    
    for winnum = 1:NumWins
        plhg_temp(winnum,:) = abs(mean(abs(tophase_high(winst:winend,:)).*exp(i*(lowphase(winst:winend,:) ...
            - highamp(winst:winend,:)))));
        % Coherence Between Screws
        coher_temp(winnum,1) = mean(mscohere(spont_all(winst:winend,1),spont_all(winst:winend,2),100,2,[],fs_EEG));
        % Coherence Between Wires
        coher_temp(winnum,2) = mean(mscohere(spont_all(winst:winend,3),spont_all(winst:winend,4),100,2,[],fs_EEG));
        % Coherence Between Ipsilateral (Screw + Wire)
        coher_temp(winnum,3) = mean(mscohere(spont_all(winst:winend,1),spont_all(winst:winend,3),100,2,[],fs_EEG));
        % Coherence Between Contralateral (Screw + Wire)
        coher_temp(winnum,4) = mean(mscohere(spont_all(winst:winend,1),spont_all(winst:winend,4),100,2,[],fs_EEG));
        
        temp_bp_calc(winnum,:)= bandpower(spont_all(winst:winend,:),fs_EEG,[1,30]);
        norm_temp_bp_calc = (temp_bp_calc - mean(temp_bp_calc))./std(temp_bp_calc);
        
        temp_bp_calc_m(winnum,:)= bandpower(spont_all(winst:winend,:),fs_EEG,[30,300]);
        norm_temp_bp_calc_m = (temp_bp_calc_m - mean(temp_bp_calc_m))./std(temp_bp_calc_m);
        
        temp_bp_calc_h(winnum,:)= bandpower(spont_all(winst:winend,:),fs_EEG,[300,1000]);
        norm_temp_bp_calc_h = (temp_bp_calc_h - mean(temp_bp_calc_h))./std(temp_bp_calc_h);
        
        winst = winst + winDisp * fs_EEG;
        winend = winst - 1 + winLen * fs_EEG;
    end
    
    plhg_evoked = plhg_temp;
    coher_evoked = coher_temp;
    norm_plhg_evoked = (plhg_evoked - mean(plhg_evoked))./std(plhg_evoked);
    norm_coher_evoked = (coher_evoked - mean(coher_evoked))./std(coher_evoked);
    clear tophase_high tophase_low lowphase highamp highphase plhg_temp NumWins coher_temp
    
    
    bp_calc_evoked{1} = temp_bp_calc;
    bp_calc_evoked{2} = temp_bp_calc_m;
    bp_calc_evoked{3} = temp_bp_calc_h;
    norm_bp_calc_evoked{1} = norm_temp_bp_calc;
    norm_bp_calc_evoked{2} = norm_temp_bp_calc_m;
    norm_bp_calc_evoked{3} = norm_temp_bp_calc_h;

%% Plot

    
filter_set = [1 30; 30 300;300 2000];

plot_duration = 55;

figure;
% X Axes Labels
xticklabel = winDisp:winDisp:floor(size(spont_all,1)/fs_EEG/winDisp - (winLen-winDisp)/winDisp)*winDisp;
xticks = round(linspace(1, size(norm_LLFn_evoked, 1), (60)./5));
xticklabels = xticklabel(xticks);

% Colormap
colormap('winter')

plot1 = subplot(14,1,1);
plot(1/fs_EEG:1/fs_EEG:length(spont_all)/fs_EEG,spont_all(:,1))
colorbar

plot1 = subplot(14,1,2);
imagesc(norm_LLFn_evoked')
caxis([-1,1])
set(plot1, 'XTick', xticks, 'XTickLabel', xticklabels)
xlim([0.25 60/winDisp])
% title(['Line Length']);
colorbar

plot2 = subplot(14,1,3);
imagesc(norm_Area_evoked')
set(plot2, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-1,2.5])
% title(['Area']);
xlim([0.25 60/winDisp])
colorbar

plot3 = subplot(14,1,4);
imagesc(norm_Energy_evoked')
set(plot3, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-1,3])
% title(['Energy']);
xlim([0.25 60/winDisp])
colorbar

plot4 = subplot(14,1,5);
imagesc(norm_Zero_Crossing_evoked')
set(plot4, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-1,1])
% title(['Zero Crossing']);
xlim([0.25 60/winDisp])
colorbar

plot5 = subplot(14,1,6);
imagesc(norm_RMS_evoked')
set(plot5, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-1,2])
% title(['RMS Amplitude']);
xlim([0.25 60/winDisp])
colorbar 

plot6 = subplot(14,1,7);
imagesc(norm_Skew_evoked')
set(plot6, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-2,2])
% title(['Skew ']);
xlim([0.25 60/winDisp])
colorbar

plot7 = subplot(14,1,8);
imagesc(norm_AEntropy_evoked')
set(plot7, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-2,2])
% title(['Entropy']);
xlim([0.25 60/winDisp])
colorbar

plot8 = subplot(14,1,9);
imagesc(norm_LP_exp_evoked')
set(plot8, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-2,2])
% title(['Lyapunov Exponent']);
xlim([0.25 60/winDisp])
colorbar

plot8 = subplot(14,1,10);
imagesc(norm_plhg_evoked')
set(plot8, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-1,1])
% title(['Phase Locked High Gamma']);
xlim([0.25 60/winDisp])
colorbar

plot8 = subplot(14,1,11);
imagesc(norm_coher_evoked')
set(plot8, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-1,1])
% title(['Coherence']);
xlim([0.25 60/winDisp])
colorbar

for i = 1:3
plots = subplot(14,1,11+i);
imagesc(norm_bp_calc_evoked{i}')
set(plots, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([0,3.5-i])
xlim([0.25 60/winDisp])
colorbar
% title(['Bandpower - ', num2str(filter_set(i,1)), ' - ',num2str(filter_set(i,2)), ' Hz']);
end
xlabel('Seconds')
