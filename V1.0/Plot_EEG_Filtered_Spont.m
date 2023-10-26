trial = 58;
maximum = 65;

figure
hold on
for ch = 1:4
plot(1/2000:1/2000:size(output_data{trial},1)/2000,output_data{trial}(:,ch)./max(output_data{trial}(:,ch)) + ch);
end

xlim([0,maximum])