close all

% Time Around 60 seconds to plot for closeup
t_int = 60;
x = 20;
start_frame = 2000 * 60.22;
color_txt = 'b';

figure

% Regular EEG Plot w Channel 1 bottom and Channel 4 top.

subplot(2,1,1)

hold on

for channel = 1:size(Csave,2)
    
    plot(1/2000:1/2000:size(Csave,1)/2000,Csave(:,channel)./max(Csave(:,channel)) + channel)
    
end

ylim([0,channel+1])

hold off

xlabel('Seconds')

% Zoomed in EEG Plot

subplot(2,1,2)

hold on

for channel = 1:size(Csave,2)
    
    plot(1/2000:1/2000:size(Csave,1)/2000,Csave(:,channel)./max(Csave(:,channel)) + channel)
    
end

xlim([t_int-x,t_int+x])
ylim([0,channel+1])

xline(start_frame./2000,strcat('--',color_txt),{num2str(start_frame)},'LineWidth',2)

hold off

xlabel('Seconds')