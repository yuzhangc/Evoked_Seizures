function plot_select_pairs_fig3A3B4A4B(path_extract, seizure, time_idx, plot_duration, filtered)

% On-Demand Seizures Facilitate Rapid Screening of Therapeutics for Epilepsy
% Authors: Yuzhang Chen, Brian Litt, Flavia Vitale, Hajime Takano
% DOI: https://doi.org/10.7554/eLife.101859

% Plots select pairs of seizures with magnification.

% Input Variables
% path_extract - path to extract data from
% seizure - pair in format [folder, trial]
% time_idx - array in format [start, end; start, end...]
% plot_duration - duration to plot
% filtered - filtered or raw traces

% Loads Data

if filtered
load(strcat(path_extract,"Filtered Seizure Data.mat"));
else
load(strcat(path_extract,"Standardized Seizure Data.mat"));
end
sz_parameters = readmatrix(strcat(path_extract,'Trials Spreadsheet.csv'));

% Finds Seizure, Calculate Normalization Factor

act_sz = find(sz_parameters(:,2) == seizure);
waveforms = output_data{act_sz};
norm_factor = max(abs(waveforms));

% Makes Figure

figure

% Plots Main Plot

subplot(2,size(time_idx,1),1:size(time_idx,1))

% Cycles Through Channels and Plots Normalized in Order of Highest (Top) ->
% Lowest Channel (Bottom)

for ch = 1:size(waveforms,2)

    hold on
    plot(1/fs : 1/fs : plot_duration + t_before,...
        waveforms(1 : (t_before + plot_duration) * fs,ch)...
        ./norm_factor(ch) + (ch-1)*1,'Color','k')
    hold off
    
end

% Apply Limits
ylim([-1,ch])
xlim([0,t_before + plot_duration])
xlabel('Time (sec)')

% Plots Enlarged Zones

for cnt = 1:size(time_idx,1)

    subplot(2,size(time_idx,1),size(time_idx,1) + cnt)

    for ch = 1:size(waveforms,2)
        hold on
        plot(1/fs : 1/fs : plot_duration + t_before,...
            waveforms(1 : (t_before + plot_duration) * fs,ch)...
            ./norm_factor(ch) + (ch-1)*1,'Color','k')
        hold off
    end

    ylim([-1,ch])
    xlim(time_idx(cnt,:))
    xlabel('Time (sec)')

end

% Sets Size

set(gcf,'Position', [294 671.5000 1583 307.5000])

end