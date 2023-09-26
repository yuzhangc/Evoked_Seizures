function [dwt_output, features,norm_features] = calculate_wavelet_features(path_extract,filter_sz, wavelets, feature_list, winLen, winDisp)

% Calculate selected features on data based on wavelets

% Input Variables
% path_extract - path for seizures.
% filter_sz - whether to calculate features for filtered or unfiltered data
% wavelets - how many transforms
% feature_list - list of features below

% 1 - Line Length

% Output Variables
% features - calculated features
% norm_featured - normalized_features
% dwt_output - discrete wavelet transform output

% -------------------------------------------------------------------------

% Import Seizure Data.

disp("Working on: " + path_extract)
if filter_sz
load(strcat(path_extract,"Filtered Seizure Data.mat"))
else
load(strcat(path_extract,"Standardized Seizure Data.mat"))
end

sz_parameters = readmatrix(strcat(path_extract,'Trials Spreadsheet.csv'));

% -------------------------------------------------------------------------

% Discrete Wavelet Transform Through Channels

for sz_cnt = 1:length(output_data)

temp_dwt = zeros(size(output_data{sz_cnt},1),wavelets + 1,size(output_data{sz_cnt},2));
    
for ch = 1:size(output_data{sz_cnt},2)
temp_dwt(:,:,ch) = modwtmra(modwt(output_data{sz_cnt}(:,ch),wavelets))';
end

dwt_output{sz_cnt} = temp_dwt;

end

% -------------------------------------------------------------------------

% Calculate Features Through Wavelets (Main Grouping is Channels)

if ismember(1, feature_list)

% Define Function

LLFn = @(x) sum(abs(diff(x)));

% Loop Through Seizures

for sz_cnt = 1:length(output_data)

temp_LLFn = [];
temp_LLFn_norm = [];

for ch = 1:size(output_data{sz_cnt},2)

    temp_LLFn(:,:,ch) = moving_window_feature_calculation(dwt_output{sz_cnt}(:,:,ch), fs, winLen, winDisp, LLFn,[]);
    temp_LLFn_norm(:,:,ch) = (temp_LLFn(:,:,ch) - mean(temp_LLFn(:,:,ch)))./std(temp_LLFn(:,:,ch));

end

features.Line_Length{sz_cnt} = temp_LLFn;
norm_features.Line_Length{sz_cnt} = temp_LLFn_norm;

end

end

% -------------------------------------------------------------------------

% Plots Wavelet Transforms

% Creates Directory
mkdir(path_extract,'Figures\Normalized Wavelets')

for sz_cnt = 1:length(output_data)

    % Generate Subplot For All Line Length Channels
    for ch = 1:size(output_data{sz_cnt},2)

        % Subplot 1 Is Raw Channel Data

        fig1 = figure(1);
        fig1.WindowState = 'maximized';

        plot1 = subplot(wavelets + 2,1,1);
    
        plot(1/fs:1/fs:t_before + t_after, output_data{sz_cnt}(:,ch)./ max(output_data{sz_cnt}(:,ch))...
                * 0.5 + size(output_data{sz_cnt},2) - ch,'k');
        xlim([0.25 60]);

        % Titles Plot

        plot_title = strcat("Raw Data | Channel ", num2str(ch));
        title(plot_title)

        % Subplot 2 - Wavelet + 1 Is Wavelet Data

        for wavelet = 1:wavelets + 1
        
        plot1 = subplot(wavelets + 2,1,1 + wavelet);
        
        % Plots DWT
        plot(1/fs:1/fs:t_before + t_after, dwt_output{sz_cnt}(:,wavelet,ch)./ max(dwt_output{sz_cnt}(:,wavelet,ch))...
                * 0.5 + size(output_data{sz_cnt},2) - ch,'k');
        xlim([0.25 60]);

        plot_title = strcat("Wavelet ", num2str(wavelet), " of ", num2str(wavelets), " | Channel ", num2str(ch));
        title(plot_title)

        end

        xlabel("Time (seconds)")

        % Saves Figures
        saveas(fig1,fullfile(strcat(path_extract,"Figures\Normalized Wavelets\Seizure ",num2str(sz_parameters(sz_cnt,2))," Ch ",num2str(ch),".png")),'png');    
        close(fig1)

    end
    
end

% -------------------------------------------------------------------------

% Plots Normalized Features Only

% Creates Directory
mkdir(path_extract,'Figures\Normalized Wavelet Features')

for sz_cnt = 1:length(output_data)

    fig1 = figure(1);
    fig1.WindowState = 'maximized';
    
    % Chooses colormap for plot
    colormap('winter')

    % First Plot is Raw Channel. Choose Wire For Most
    plot1 = subplot(size(output_data{sz_cnt},2) + 1,1,1);
    if size(output_data{sz_cnt}) > 2
        channel = 3;
    else
        channel = 1;
    end
    plot(1/fs:1/fs:t_before + t_after, output_data{sz_cnt}(:,channel)./ max(output_data{sz_cnt}(:,channel))...
            * 0.5 + size(output_data{sz_cnt},2) - channel,'k');
    xlim([0.25 60]);
    colorbar;

    % Generate Subplot For All Line Length Channels
    for ch = 1:size(output_data{sz_cnt},2)

        plot1 = subplot(size(output_data{sz_cnt},2) + 1,1,1 + ch);

        feature_names = fieldnames(norm_features);
        
        % Plots with colorbar
        imagesc(norm_features.(feature_names{1}){sz_cnt}(:,:,ch)');
        colorbar

        % Generate Tick Labels For Plots
        xticklabel = winDisp:winDisp:floor(size(output_data{sz_cnt},1)/fs/winDisp - (winLen-winDisp)/winDisp)*winDisp;
        xticks = round(linspace(1, size(norm_features.(feature_names{1}){sz_cnt}, 1), (t_after+t_before)./5));
        xticklabels = xticklabel(xticks);
        
        % Set X Ticks For Plots
        set(plot1, 'XTick', xticks, 'XTickLabel', xticklabels)
        xlim([0.25 60/winDisp]);

        caxis([-1,1])

        % Uses Feature Name as Title, Removing Underscores and Replacing
        % With Spaces
        plot_title = strrep(feature_names{1},"_"," ");
        title(plot_title)

    end

    % Saves Figures
    saveas(fig1,fullfile(strcat(path_extract,"Figures\Normalized Wavelet Features\Seizure ",num2str(sz_parameters(sz_cnt,2)),".png")),'png');    
    close(fig1)
    
end

% -------------------------------------------------------------------------

% Saves Features

save(strcat(path_extract,'Raw Wavelet Features.mat'),'t_after','t_before','sz_parameters','winLen','winDisp','features','filter_sz','fs',"-v7.3");
save(strcat(path_extract,'Normalized Wavelet Features.mat'),'t_after','t_before','sz_parameters','winLen','winDisp','norm_features','filter_sz','fs',"-v7.3");

end