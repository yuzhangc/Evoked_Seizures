% Plots for Subsections.

subplot(2,2,4)
i = 13 % 1 3 12 Change for Feature
hold off
k = 1 % Change Depending on Number Subcategories
errorbar(1:1:size(comparison_plot{i},2),mean(comparison_plot{i}(subdiv_index{k},:)),...
1.96*std(comparison_plot{i}(subdiv_index{k},:))./sqrt(length(subdiv_index{k})),':o',...
'Color',Colorset_plot(k,:),'LineWidth',2)
hold on
k = 2
errorbar(1:1:size(comparison_plot{i},2),mean(comparison_plot{i}(subdiv_index{k},:)),...
1.96*std(comparison_plot{i}(subdiv_index{k},:))./sqrt(length(subdiv_index{k})),':o',...
'Color',Colorset_plot(k,:),'LineWidth',2)
xticks(1:length(to_visualize))
xticklabels({'Pre-Seizure','Stimulation','Sz - Beginning','Sz - Middle','Sz - End','Post Ictal'})
    xtickangle(30)
        yline(0,'-k','LineWidth',1)
        
% All Together
subplot(2,3,1)
i = 1 % i = 1 6 12;
hold off
errorbar(mean(comparison_plot{i}),1.96*std(comparison_plot{i})./sqrt(size(comparison_plot{i},1)),'ko','LineWidth',2)
hold on
for j = 1:length(to_visualize)
   scatter(j - 0.5 + rand(1,length(comparison_plot{i}(:,j))),comparison_plot{i}(:,j),2,'filled')
end

yline(0,'-k','LineWidth',1)
xticks(1:length(to_visualize))
xticklabels({'Pre-Seizure','Stimulation','Sz - Beginning','Sz - Middle','Sz - End','Post Ictal'})
xtickangle(45)
ylim([-1,6])