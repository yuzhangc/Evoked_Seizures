function [sz_corr, sz_lag, sz_grp] = calculate_seizure_corr(path_extract, channels, to_plot)

mkdir(path_extract,'Figures\Correlation')

% Calculates Correlation (w Time Lag) between all seizures and events in
% single animals

% Input Variables
% path_extract - path for normalized seizure features and seizure
% parameters
% to_plot - show plots or not
% channels - which channel to use for calculation
 
% Output Variables
% sz_corr - list of correlation coeffients
% sz_lag - list of seizure lags
% sz_grp - matrix containing pairing information (which seizures were
% calculated) in first two columns, and pairing categorization in the third
% column. Pairing categorization is as follows:
% 1 - Spontaneous Success vs Sponaneous Success
% 2 - Spontaneous Success vs Evoked Success
% 3 - Spontaneous Success vs Evoked Failed
% 4 - Evoked Success vs Evoked Success
% 5 - Evoked Success vs Evoked Failed
% 6 - Evoked Failed vs Evoked Failed

% -------------------------------------------------------------------------

% Step 1: Loads Features and Seizure Parameters

load(strcat(path_extract,'Filtered Seizure Data.mat'));
sz_parameters = readmatrix(strcat(path_extract,'Trials Spreadsheet.csv'));

% Generates Upper Triangle Matrix (List of Trials to Compare)
list_of_trials = triu(ones(size(output_data,2)),1);

% Sets Up Output Variables
sz_corr = []; sz_lag = []; sz_grp = [];

% -------------------------------------------------------------------------

% Step 2: Performs Calculation Across All Channels

for cnt = 1:length(channels)

    % Extracts Relevant channel
    ch = channels(cnt);
    disp(strcat("Working on Channel ", num2str(ch)));

    % Sets Up Temporary Output Variables
    temp_sz_corr = []; temp_sz_lag = []; temp_sz_grp = [];

    total_trials_completed = 0;

    % Loops Through All Trial Combinations
    for seizure_1 = 1:size(list_of_trials,2)
    for seizure_2 = 1:size(list_of_trials,2)

        % Perform Calculation Only If Part of Upper Triangle Matrix Above
        % Main Diagonal

        if list_of_trials(seizure_1,seizure_2) == 1

        % Displays Progress
        if rem(total_trials_completed,100) == 0
            disp(strcat("Correlation #", num2str(total_trials_completed)," out of ", ...
                num2str(sum(sum(list_of_trials))), " Calculations Completed"))
        end

        
        % Calculates Correlation W Lags
        [c,lags] = xcorr(output_data{seizure_1}(:,ch),output_data{seizure_2}(:,ch));
        
        % Only Interested in Maximum (Positive) Correlation and Lags
        temp_sz_corr = [temp_sz_corr ; max(c)];
        temp_sz_lag = [temp_sz_lag ; lags(find(max(c) == c))];
        
        % Determine Seizure Groupings
        
        % Seizure 1 Info

        sz_1_spont = 0;
        sz_1_success = 0;

        if (sz_parameters(seizure_1,8) == -1)
            sz_1_spont = 1;
            sz_1_success = 1;
        elseif sz_parameters(seizure_1,5) == 1
            sz_1_success = 1;
        end

        % Seizure 2 Info
       
        sz_2_spont = 0;
        sz_2_success = 0;

        if (sz_parameters(seizure_2,8) == -1)
            sz_2_spont = 1;
            sz_2_success = 1;
        elseif sz_parameters(seizure_2,5) == 1
            sz_2_success = 1;
        end

        % 1 - Spontaneous Success vs Sponaneous Success
        if sz_1_spont && sz_2_spont
            sz_grping = 1;

        % 2 - Spontaneous Success vs Evoked Success
        elseif (sz_1_spont && ~sz_2_spont && sz_2_success) || (sz_2_spont && ~sz_1_spont && sz_1_success)
            sz_grping = 2;

        % 3 - Spontaneous Success vs Evoked Failed
        elseif (sz_1_spont && ~sz_2_spont && ~sz_2_success) || (sz_2_spont && ~sz_1_spont && ~sz_1_success)
            sz_grping = 3;

        % 4 - Evoked Success vs Evoked Success
        elseif (~sz_1_spont && sz_1_success && ~sz_2_spont && sz_2_success)
            sz_grping = 4;

        % 5 - Evoked Success vs Evoked Failed
        elseif (~sz_1_spont && sz_1_success && ~sz_2_spont && ~sz_2_success) || (~sz_1_spont && ~sz_1_success && ~sz_2_spont && sz_2_success)
            sz_grping = 5;

        % 6 - Evoked Failed vs Evoked Failed
        elseif (~sz_1_spont && ~sz_1_success && ~sz_2_spont && ~sz_2_success)
            sz_grping = 6;
        end

        temp_sz_grp = [temp_sz_grp; seizure_1, seizure_2, sz_grping];

        clear c lags sz_grping

        % Update Trial Progress Tracker
        total_trials_completed = total_trials_completed + 1;

        end

    end
    end

    % Assigns Temporary Output to True Output Index
    sz_corr{cnt} = temp_sz_corr;
    sz_lag{cnt} = temp_sz_lag;
    sz_grp{cnt} = temp_sz_grp;

    disp(strcat("Channel ", num2str(ch), " Completed"))

end

disp('Cross Correlation With Lag Completed')

% -------------------------------------------------------------------------

% Step 3: Plots Figures

if to_plot

    % Correlation Raw Plot

    fig1 = figure(1);
    fig1.WindowState = 'maximized';

    % Loops Through Channels

    for cnt = 1:length(channels)

        subplot(1,length(channels),cnt)
        hold on
        
        % Scatterplots Raw Data
        scatter(sz_grp{cnt}(:,3) + rand(length(sz_grp{cnt}(:,3)),1) * 0.5 - 0.25 , sz_corr{cnt} ,'filled')

        % Regroups Data and Calculates Median and Standard Error (95%
        % Confidence Interval)
        
        med_matrix = []; sterror_matrix = [];

        for grouping = 1:6
        med_matrix(grouping) = median(sz_corr{cnt}(sz_grp{cnt}(:,3) == grouping));
        sterror_matrix(grouping) = 1.95 * std(sz_corr{cnt}(sz_grp{cnt}(:,3) == grouping))./sqrt(sum(sz_grp{cnt}(:,3) == grouping));
        end

        % Errorbar Plot
        errorbar(med_matrix, sterror_matrix,'or','LineWidth',2)

        hold off

        % X Ticks
        xticks(unique(sz_grp{cnt}(:,3)));
        xtickoptions = {'Spont vs Spont','Spont vs Evoked','Spont vs Failed','Evoked vs Evoked','Evoked vs Failed','Failed vs Failed'};
        xticklabels(xtickoptions(unique(sz_grp{cnt}(:,3))));
        xtickangle(45);

        % Y Label and Title
        ylabel('Cross Correlation')
        title(strcat("Channel ",num2str(channels(cnt))));

    end

    % Saves Figure

    figure_title = "Figures\Correlation\Raw Cross Correlation Plot";
    saveas(fig1,fullfile(strcat(path_extract,figure_title,".png")),'png');

    close(fig1)

    % -----------------------------------------------------------------

    % Lag Raw Plot

    fig2 = figure(2);
    fig2.WindowState = 'maximized';

    % Loops Through Channels

    for cnt = 1:length(channels)

        subplot(1,length(channels),cnt)
        hold on
        
        % Scatterplots Raw Data
        scatter(sz_grp{cnt}(:,3) + rand(length(sz_grp{cnt}(:,3)),1) * 0.5 - 0.25 , sz_lag{cnt}./fs ,'filled')

        % Regroups Data and Calculates Median and Standard Error (95%
        % Confidence Interval)
        
        med_matrix = []; sterror_matrix = [];

        for grouping = 1:6
        med_matrix(grouping) = median(sz_lag{cnt}(sz_grp{cnt}(:,3) == grouping))./fs;
        sterror_matrix(grouping) = 1.95 * std(sz_lag{cnt}(sz_grp{cnt}(:,3) == grouping))./sqrt(sum(sz_grp{cnt}(:,3) == grouping))./fs;
        end

        % Errorbar Plot
        errorbar(med_matrix, sterror_matrix,'or','LineWidth',2)

        hold off

        % X Ticks
        xticks(unique(sz_grp{cnt}(:,3)));
        xtickoptions = {'Spont vs Spont','Spont vs Evoked','Spont vs Failed','Evoked vs Evoked','Evoked vs Failed','Failed vs Failed'};
        xticklabels(xtickoptions(unique(sz_grp{cnt}(:,3))));
        xtickangle(45);

        % Y Label and Title
        ylabel('Lag For Maximum Cross Correlation (sec)')
        title(strcat("Channel ",num2str(channels(cnt))));

    end

    % Saves Figure

    figure_title = "Figures\Correlation\Raw Lag for Max Cross Correlation Plot";
    saveas(fig2,fullfile(strcat(path_extract,figure_title,".png")),'png');

    close(fig2)

    % -----------------------------------------------------------------

    for cnt = 1:length(channels)

    % Anova Test For Correlation
    [p, tbl, stats] = anova1(sz_corr{cnt}, sz_grp{cnt}(:,3));
    boxplot(sz_corr{cnt},sz_grp{cnt}(:,3),'Symbol','')

    % Saves ANOVA Results
    txt_name = strcat("Figures\Correlation\ANOVA Cross Correlation Channel ", num2str(channels(cnt)));
    writecell(tbl,fullfile(strcat(path_extract,txt_name,".txt")));

    % X Ticks
    xticks(1:6);
    xtickoptions = {'Spont vs Spont','Spont vs Evoked','Spont vs Failed','Evoked vs Evoked','Evoked vs Failed','Failed vs Failed'};
    xticklabels(xtickoptions(unique(sz_grp{cnt}(:,3))));
    xtickangle(45);

    % Y Label
    ylabel('Cross Correlation')

    % Positioning and Saving
    figure_handle = gcf;
    set(figure_handle,'Position',[2 42 958 962.5000]);

    figure_title = strcat("Figures\Correlation\ANOVA Cross Correlation Channel ", num2str(channels(cnt)));
    saveas(figure_handle,fullfile(strcat(path_extract,figure_title,".png")),'png');

    close(figure_handle)

    end

    % -----------------------------------------------------------------

    for cnt = 1:length(channels)

    % Anova Test For Lag
    [p, tbl, stats] = anova1(sz_lag{cnt}, sz_grp{cnt}(:,3));

    % Saves ANOVA Results
    txt_name = strcat("Figures\Correlation\ANOVA Lag For Max Cross Correlation Channel ", num2str(channels(cnt)));
    writecell(tbl,fullfile(strcat(path_extract,txt_name,".txt")));

    % X Ticks
    xticks(1:6);
    xtickoptions = {'Spont vs Spont','Spont vs Evoked','Spont vs Failed','Evoked vs Evoked','Evoked vs Failed','Failed vs Failed'};
    xticklabels(xtickoptions(unique(sz_grp{cnt}(:,3))));
    xtickangle(45);

    % Y Label
    ylabel('Lag For Maximum Cross Correlation (sec)')

    % Positioning and Saving
    figure_handle = gcf;
    set(figure_handle,'Position',[2 42 958 962.5000]);

    figure_title = strcat("Figures\Correlation\ANOVA Lag For Max Cross Correlation Channel ", num2str(channels(cnt)));
    saveas(figure_handle,fullfile(strcat(path_extract,figure_title,".png")),'png');

    close(figure_handle)

    end

end

end

