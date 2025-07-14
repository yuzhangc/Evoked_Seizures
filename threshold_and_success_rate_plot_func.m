function [] = threshold_and_success_rate_plot_func(directory,min_thresh_list,seizure_duration_list,freely_moving)

% On-Demand Seizures Facilitate Rapid Screening of Therapeutics for Epilepsy
% Authors: Yuzhang Chen, Brian Litt, Flavia Vitale, Hajime Takano
% DOI: https://doi.org/10.7554/eLife.101859

% Makes a few basic plots about evocation threshold in epileptic vs naive
% animals and successful evocation ratios

% Input Variables
% 1) directory - main directory, which should contain a 'Animal Master.csv'
% file containing information about each animal subject
% 
% 2) min_thresh_list - a group of min_thresh outputs from predict_seizure_duration
% function, which has below components
% power - power at which 2/3 of time reliably induce seizures
% duration - duration at which 2/3 of time reliably induce seizures
% seizures - trial #s for evoked events above min power AND duration
%       (excluding diazepam)
% avg_success - success rate for evocation above min power AND duration or
%       for ALL if threshold was not found (excluding diazepam)
% diaz_seizures - trial # for diazepam seizures above threshold
% diaz_success - success rate for evocation with diazepam
% 
% 3) seizure_duration_list - list of predicted seizure durations
%
% 4) freely_moving - Freely Moving or Head Fixed. Determines Animal Master
% List

% No Output Variables. Outputs Four Figures

% -------------------------------------------------------------------------

% Step 1: Reads Animal Master Spreadsheet

if not(freely_moving)
animal_info = readmatrix(strcat(directory,'Animal Master Head Fixed.csv'));
else
animal_info = readmatrix(strcat(directory,'Animal Master.csv'));
end

% Step 2: Extract threshold power and duration from min_thresh_list.

% In the event power is -1, no threshold for evocation was determined,
% exclude these trials by performing a union function, and set the indices
% to plot as the opposite of 'no threshold determined' trials.

list_of_power = [min_thresh_list.power]; list_of_duration = [min_thresh_list.duration];
invalid_power = find(list_of_power == -1); invalid_duration = find(list_of_duration == -1);
bad_indices = union(invalid_power,invalid_duration); indx_to_plot = not(ismember(1:length(min_thresh_list),bad_indices));

% Step 3: Generate Indices List

% Determine epileptic, naive, and detected threshold (indx_to_plot = 1) or
% not (0). Epileptic or naive is column 5 in animal information master
% sheet.

indx_to_plot_epileptic = find (indx_to_plot' == 1 & animal_info(:,5) == 1);
indx_to_plot_naive = find (indx_to_plot' == 1 & animal_info(:,5) == 0);
und_thresh_epileptic = find (indx_to_plot' == 0 & animal_info(:,5) == 1);
und_thresh_naive = find (indx_to_plot' == 0 & animal_info(:,5) == 0);

% -------------------------------------------------------------------------

% Step 4: Plot 1 - Threshold Power vs Threshold Duration

% This scatterplot plots threshold power against threshold duration (when
% both exists)

figure;

hold on
scatter(list_of_power(indx_to_plot_epileptic),list_of_duration(indx_to_plot_epileptic),'filled',"MarkerFaceColor", [1 0 0]);
scatter(list_of_power(indx_to_plot_naive),list_of_duration(indx_to_plot_naive),'filled',"MarkerFaceColor", [0 0 1]);
hold off

xlabel('Threshold Power (mW)')
ylabel('Threshold Duration (sec)')
legend('Epileptic', 'Naive')

% -------------------------------------------------------------------------

% Step 5: Figure A2 B - Distribution of Threshold Power

% This is a distribution of seizure threshold power, organized into
% epileptic (blue) and naive (yellow) histograms with equal spacing

figure;

hold on
h1 = histogram(list_of_power(list_of_power' ~= -1 & animal_info(:,5) == 1),'FaceColor',[1 0 0]);
h1.BinWidth = 5;
h2 = histogram(list_of_power(list_of_power' ~= -1 & animal_info(:,5) == 0),'FaceColor',[0 0 1]);
h2.BinWidth = 5;
hold off

legend ('Epileptic','Naive')
xlabel('Threshold Power (mW)')
ylabel('Count')

% This limit excludes the 25mW+ threshold, which only happened when I was
% learning to use the fiber.
xlim([0,25])

% -------------------------------------------------------------------------

% Step 6: Figure A2 C - Distribution of Threshold Duration

% This is a distribution of seizure threshold power, organized into
% epileptic (blue) and naive (yellow) histograms with equal spacing

figure;

hold on
% To ONLY Includes True Threshold. Add '& list_of_power' ~= -1'
% to get all animals
h1 = histogram(list_of_duration(list_of_duration' ~= -1 & animal_info(:,5) == 1),'FaceColor',[1 0 0]);
h1.BinWidth = 2;
h2 = histogram(list_of_duration(list_of_duration' ~= -1 & animal_info(:,5) == 0),'FaceColor',[0 0 1]);
h2.BinWidth = 2;
hold off

legend ('Epileptic','Naive')
xlabel('Threshold Duration (sec)')
ylabel('Count')

% -------------------------------------------------------------------------

% Step 7: Figure A2 D - Average Success Rate

% This plot contains epileptic data on the left and naive data on the right,
% using blue for epileptic, red for naive, and yellow for all trials
% where a threshold was not detected. If no threshold is detected, the average 
% evocation success across all trials was used. For trials with threshold, 
% percentage is the percentage success of number of above threshold trials.

% Extracts Percent Success from min_thresh_list. Remember that when
% threshold is determined, percent success is only for trials above
% threshold. When threshold is not determined, percent success if for ALL
% trials.

avg_success_list = [min_thresh_list.avg_success];

figure;

% Sorts Success Rate Y Axes
yaxis1 = sort(avg_success_list(indx_to_plot_epileptic) .* 100);
yaxis2 = sort(avg_success_list(indx_to_plot_naive) .* 100);
yaxis3 = sort(avg_success_list(und_thresh_epileptic) .* 100);
yaxis4 = sort(avg_success_list(und_thresh_naive) .* 100);

% Default X Axes
xaxis1 = ones(length(indx_to_plot_epileptic),1);
xaxis2 = ones(length(indx_to_plot_naive),1) .* 3;
xaxis3 = ones(length(und_thresh_epileptic),1);
xaxis4 = ones(length(und_thresh_naive),1) .* 3;

% Make X Axes Distribute Evenly According to Unique Y Axis Values

% Yaxis1

[a,b,c] = unique(yaxis1);
for cnt = 1:max(c)
    % No need to adjust if only 1 Value
    if sum(cnt == c) == 1
    else
        indexes = find(c == cnt);
        for index = 1:length(indexes)
            xaxis1(indexes(index)) = xaxis1(indexes(index)) - 0.5 + index/(sum(cnt == c)+1);
        end
    end
end

% Yaxis2

[a,b,c] = unique(yaxis2);
for cnt = 1:max(c)
    if sum(cnt == c) == 1
    else
        indexes = find(c == cnt);
        for index = 1:length(indexes)
            xaxis2(indexes(index)) = xaxis2(indexes(index)) - 0.5 + index/(sum(cnt == c)+1);
        end
    end
end

% Yaxis3

[a,b,c] = unique(yaxis3);
for cnt = 1:max(c)
    if sum(cnt == c) == 1
    else
        indexes = find(c == cnt);
        for index = 1:length(indexes)
            xaxis3(indexes(index)) = xaxis3(indexes(index)) - 0.5 + index/(sum(cnt == c)+1);
        end
    end
end

% Yaxis4

[a,b,c] = unique(yaxis4);
for cnt = 1:max(c)
    if sum(cnt == c) == 1
    else
        indexes = find(c == cnt);
        for index = 1:length(indexes)
            xaxis4(indexes(index)) = xaxis4(indexes(index)) - 0.5 + index/(sum(cnt == c)+1);
        end
    end
end

% Perform scatterplot

hold on
scatter(xaxis1, yaxis1, 'filled',"MarkerFaceColor", [1 0 0])
scatter(xaxis2, yaxis2, 'filled',"MarkerFaceColor", [0 0.4470 0.7410])
scatter(xaxis3, yaxis3, 'filled',"MarkerFaceColor",[0.9290 0.6940 0.1250])
scatter(xaxis4, yaxis4,'filled',"MarkerFaceColor",[0.9290 0.6940 0.1250])
hold off

% Legends, X and Y Axes Labels, Titles

legend('Epileptic','Naive','Under Threshold','Location','southwest')
xticks([1, 3])
xlim([0 4])
xticklabels({'Epileptic','Naive'})
xline(2,'--k');
ylabel('Success Rate (%)')

% -------------------------------------------------------------------------

% Step 8: Figure A2 E - Average Above Threshold Duration

% Sets up output variables

avg_above_thresh_epileptic = [];
avg_above_thresh_naive = [];

% Sets up counters

cnt_epileptic = 1;
cnt_naive = 1;

for detected_threshold = 1:length(indx_to_plot)
    
    % Threshold & Epileptic
    
    if indx_to_plot(detected_threshold) == 1 && animal_info(detected_threshold,5) == 1
        
        seizures = seizure_duration_list{detected_threshold};
        above_thresh = min_thresh_list(detected_threshold).seizures;
        avg_above_thresh_epileptic(cnt_epileptic) = mean(seizures(above_thresh));
        cnt_epileptic = cnt_epileptic + 1;
    
    % Threshold & Naive
    
    elseif indx_to_plot(detected_threshold) == 1 && animal_info(detected_threshold,5) == 0
        
        seizures = seizure_duration_list{detected_threshold};
        above_thresh = min_thresh_list(detected_threshold).seizures;
        avg_above_thresh_naive(cnt_naive) = mean(seizures(above_thresh));
        cnt_naive = cnt_naive + 1;
        
    else
    end
end

% Temporary Fix to Remove Zeros (No Detected Duration Due to Invalid Model or Channel Incongruency)

avg_above_thresh_epileptic = avg_above_thresh_epileptic(avg_above_thresh_epileptic ~= 0);
avg_above_thresh_naive = avg_above_thresh_naive(avg_above_thresh_naive ~= 0);

figure;

% Define X Axes to Include Small Amount of Randomness

xaxis1 = ones(length(avg_above_thresh_epileptic),1) - 0.1 + 0.2*rand(length(avg_above_thresh_epileptic),1);
xaxis2 = ones(length(avg_above_thresh_naive),1) .* 3 - 0.1 + 0.2*rand(length(avg_above_thresh_naive),1);

% Scatter Plot

hold on
scatter(xaxis1, avg_above_thresh_epileptic, 'filled',"MarkerFaceColor", [1 0 0]);
scatter(xaxis2, avg_above_thresh_naive, 'filled',"MarkerFaceColor", [0 0.4470 0.7410]);

% Errorbar

disp("Epileptic Mean and STD - Duration of Events")
mean(avg_above_thresh_epileptic)
std(avg_above_thresh_epileptic)

disp("Naive Mean and STD - Duration of Events")
mean(avg_above_thresh_naive)
std(avg_above_thresh_naive)

disp("Rank Sum Test of Duration")
ranksum(avg_above_thresh_naive, avg_above_thresh_epileptic)

% x_errorbar = [1,3];
% errorbar(x_errorbar,[mean(avg_above_thresh_epileptic),mean(avg_above_thresh_naive)],...
%    [std(avg_above_thresh_epileptic),std(avg_above_thresh_naive)],'ko','LineWidth',2);

hold off

legend('Epileptic','Naive')
xticks([1, 3])
xlim([0 4])
xticklabels({'Epileptic','Naive'})
xline(2,'--k');
ylabel('Average Duration (sec)')


end
