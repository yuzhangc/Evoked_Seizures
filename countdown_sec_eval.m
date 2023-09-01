% Temporary Code to Find Minimum Error Given Countdown Sec Changes

cnt = 1
comparisons = [];

for countdown_sec = 4.5:0.5:5

for folder_num = 1:length(subFolders)
    
    path_extract = strcat(directory,subFolders(folder_num).name,'\');
    seizure_duration = predict_seizure_duration(path_extract,sz_model,countdown_sec,to_fix_chart,to_plot);
    seizure_duration_list(folder_num) = {seizure_duration};

end

temp_sz_list = [];
for an = 1:37
    temp_sz_list = [temp_sz_list;seizure_duration_list{an}]
end

comparisons(cnt,:) = [countdown_sec, sum(abs(master_sz_list - temp_sz_list) < 1)./length(master_sz_list)]
cnt = cnt + 1;

end

