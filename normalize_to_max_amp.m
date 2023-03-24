function [output_data] = normalize_to_max_amp(seizure_data,baseline_data)

% Normalizes seizure data to max amplitude
% In theory, makes data more comparable across different recording
% setups...since the maximum signal is always going to be 1. However, this
% is assuming that the theoretical maximum signal in each brain is the
% same, which may or may not be the case.
% Input Variable - seizure_data - seizure which to normalize
% Output Variable - output_data - normalized seizure data

if isempty(baseline_data)
    for sz_cnt = 1:length(seizure_data)
        output_data{sz_cnt} = seizure_data{sz_cnt}./max(abs(seizure_data{sz_cnt}));
    end
else
end

end