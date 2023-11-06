ch = 3
grp1 = 1; grp2 = 2;
p_val = 0.05;
test_array = nan(max(sum(sz_grp{ch}(:,grp1) == 1),sum(sz_grp{ch}(:,3) == grp2)),2);
test_array(1:sum(sz_grp{ch}(:,3) == grp1),1) = sz_corr{ch}(sz_grp{ch}(:,3) == grp1);
test_array(1:sum(sz_grp{ch}(:,3) == grp2),2) = sz_corr{ch}(sz_grp{ch}(:,3) == grp2);
ttest(test_array(:,1),test_array(:,2));
[h,p]=ttest(test_array(:,1),test_array(:,2));
p_sig = p_val/((sum(sum(sz_grp{1}(:,3) == grp1) + sum(sz_grp{1}(:,3) == grp2)) * (sum(sum(sz_grp{1}(:,3) == grp1) + sum(sz_grp{1}(:,3) == grp2)) - 1))/2);
p<p_sig