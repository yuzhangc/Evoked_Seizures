t = 10; % t_in seconds
t_st = 10; % Time to Start
ch = 14;

std_t = 10;

std_list = [];

ylimits = [-250,250];

figure;

subplot(4,2,1)
modded_read_Intan_RHD2000_file('0419_OFF_240419_160119.rhd', 'E:\');

plot(t_st:1/20000:(t_st+t),amplifier_data(ch,t_st*20000:1:(t_st+t)*20000),'k')
ylim(ylimits)
xlim([t_st,t_st+t])
std_list(1) = std(amplifier_data(ch,t_st*20000:1:(t_st+std_t)*20000));
title('Off (0) Trial 1')

subplot(4,2,2)
modded_read_Intan_RHD2000_file('0419_OFF_ROUND2_240419_161120.rhd', 'E:\');

plot(t_st:1/20000:(t_st+t),amplifier_data(ch,t_st*20000:1:(t_st+t)*20000),'k')
ylim(ylimits)
xlim([t_st,t_st+t])
temp_std_list = std(amplifier_data(ch,t_st*20000:1:(t_st+std_t)*20000));
std_list(1) = mean([std_list(1),temp_std_list]);
title('Off (0) Trial 2')

subplot(4,2,3)
modded_read_Intan_RHD2000_file('0419_ON_1_240419_161004.rhd', 'E:\');

plot(t_st:1/20000:(t_st+t),amplifier_data(ch,t_st*20000:1:(t_st+t)*20000),'k')
ylim(ylimits)
xlim([t_st,t_st+t])
std_list(2) = std(amplifier_data(ch,t_st*20000:1:(t_st+std_t)*20000));
title('ON (1) - 75 microW')

subplot(4,2,4)
modded_read_Intan_RHD2000_file('0419_ON_2_240419_160002.rhd', 'E:\');

plot(t_st:1/20000:(t_st+t),amplifier_data(ch,t_st*20000:1:(t_st+t)*20000),'k')
ylim(ylimits)
xlim([t_st,t_st+t])
std_list(3) = std(amplifier_data(ch,t_st*20000:1:(t_st+std_t)*20000));
title('ON (2) - 0.20 milliW')

subplot(4,2,5)
modded_read_Intan_RHD2000_file('0419_ON_3_240419_160551.rhd', 'E:\');

plot(t_st:1/20000:(t_st+t),amplifier_data(ch,t_st*20000:1:(t_st+t)*20000),'k')
ylim(ylimits)
xlim([t_st,t_st+t])
std_list(4) = std(amplifier_data(ch,t_st*20000:1:(t_st+std_t)*20000));
title('ON (3) - 0.30 milliW')

subplot(4,2,6)
modded_read_Intan_RHD2000_file('0419_ON_4_240419_155708.rhd', 'E:\');

plot(t_st:1/20000:(t_st+t),amplifier_data(ch,t_st*20000:1:(t_st+t)*20000),'k')
ylim(ylimits)
xlim([t_st,t_st+t])
std_list(5) = std(amplifier_data(ch,t_st*20000:1:(t_st+std_t)*20000));
title('ON (4) - 1.07 milliW')

subplot(4,2,7)
modded_read_Intan_RHD2000_file('0419_ON_5_240419_160406.rhd', 'E:\');

plot(t_st:1/20000:(t_st+t),amplifier_data(ch,t_st*20000:1:(t_st+t)*20000),'k')
ylim(ylimits)
xlim([t_st,t_st+t])
std_list(6) = std(amplifier_data(ch,t_st*20000:1:(t_st+std_t)*20000));
title('ON (5) - 2.10 milliW')

subplot(4,2,8)
modded_read_Intan_RHD2000_file('0419_ON_6_240419_155255.rhd', 'E:\');

plot(t_st:1/20000:(t_st+t),amplifier_data(ch,t_st*20000:1:(t_st+t)*20000),'k')
ylim(ylimits)
xlim([t_st,t_st+t])
std_list(7) = std(amplifier_data(ch,t_st*20000:1:(t_st+std_t)*20000));
title('ON (6) - 2.50 milliW')

integrated_std_list = [7.9012   11.3906   10.7864   13.3212   11.3027    8.4697    6.2366    8.7610
    7.3881   11.3397   10.8181   13.3364   11.5322    9.5235    6.3669    9.1007
    7.8343   11.5349   10.7952   14.5460   10.3889    9.3313    7.1293    8.8856
    7.6073   12.8779   11.1706   14.2558   10.7644    8.7873    7.4668    9.1735
    8.2449   12.2835   11.0977   13.6777   11.1038    9.6518    6.7706    7.9537
    7.3542   10.4412   10.6936   14.1567   11.2163    8.6879    6.6901   10.3366
    9.2099   13.4911   12.3521   14.1901   11.0389   10.1536    7.1497    9.1684];

x_axis = [0.005 0.075 0.2 0.3 1.07 2.1 2.5];

figure;
hold on
errorbar(x_axis,mean(integrated_std_list,2),std(integrated_std_list'),'k','LineWidth',1)
plot(x_axis,mean(integrated_std_list,2),'k','LineWidth',3)
for col = 1:size(integrated_std_list,2)
    scatter (x_axis,integrated_std_list(:,col),10,'filled')
end
ylim([0,20])

xlabel('LED Power milliWatt')
ylabel('Background Standard Deviation')