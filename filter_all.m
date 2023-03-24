function [output_data,notch_data] = filter_all(seizure_data,filter_list,fs)

% Filters Seizure Data According to a x row by 2 column filter list, where
% x is the number of filter combos
% Input Variables
% seizure_data - EEG data to be filtered
% filter_list - x row by 2 column filter list
% fs - frequency bands
% Output Variable
% output_data - giant cell structure primarily subdivided into filter sets
% and secondarily by seizure number

% Notch Filter
wo = 60/(fs/2);  
bw = wo/35;
[b,a] = iirnotch(wo,bw);

wo = 60*2/(fs/2);  
bw = wo/35;
[b_2,a_2] = iirnotch(wo,bw);

wo = 60*3/(fs/2);  
bw = wo/35;
[b_3,a_3] = iirnotch(wo,bw);

wo = 60*4/(fs/2);  
bw = wo/35;
[b_4,a_4] = iirnotch(wo,bw);

wo = 60*5/(fs/2);  
bw = wo/35;
[b_5,a_5] = iirnotch(wo,bw);

['Notch Filter First']

filtered_data = [];
for sz_cnt = 1:length(seizure_data)
    ['Filtering Seizure #', num2str(sz_cnt)]
    filtered_data{sz_cnt} = filtfilt(b,a,seizure_data{sz_cnt});
    filtered_data{sz_cnt} = filtfilt(b_2,a_2,filtered_data{sz_cnt});
    filtered_data{sz_cnt} = filtfilt(b_3,a_3,filtered_data{sz_cnt});
    filtered_data{sz_cnt} = filtfilt(b_4,a_4,filtered_data{sz_cnt});
    filtered_data{sz_cnt} = filtfilt(b_5,a_5,filtered_data{sz_cnt});
end

notch_data = filtered_data;

for filters = 1:size(filter_list,1)

    temp_filtered = [];
    ['Filtering based off of Filter #',num2str(filters),': ', num2str(filter_list(filters,1)),'Hz and ',...
        num2str(filter_list(filters,2)),'Hz bands']
    
    for sz_cnt = 1:length(seizure_data)
        temp_filtered{sz_cnt} = bandpass(filtered_data{sz_cnt},filter_list(filters,:),fs);
        ['Filtering Seizure #', num2str(sz_cnt)]
    end
    
    output_data{filters} = temp_filtered;

end

['Filtering Complete']

end