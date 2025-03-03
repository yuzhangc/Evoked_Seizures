net = [      0    0.5805;
0.2500    0.7432;
0.5000    0.8040;
0.7500    0.8176;
1.0000    0.8313;
1.2500    0.8283;
1.5000    0.8146;
1.7500    0.7948;
2.0000    0.7842;
2.2500    0.7523;
2.5000    0.7340;
2.7500    0.7204;
3.0000    0.6915;
3.2500    0.6657;
3.5000    0.6550;
3.7500    0.6429;
4.0000    0.6170;
4.2500    0.6049;
4.5000    0.5881;
4.7500    0.5775;
5.0000    0.5608]
knn = [      0    0.3116;
0.2500    0.4453;
0.5000    0.5547;
0.7500    0.6474;
1.0000    0.6976;
1.2500    0.7432;
1.5000    0.7720;
1.7500    0.7979;
2.0000    0.8283;
2.2500    0.8404;
2.5000    0.8435;
2.7500    0.8526;
3.0000    0.8632;
3.2500    0.8617;
3.5000    0.8647;
3.7500    0.8663;
4.0000    0.8602;
4.2500    0.8526;
4.5000    0.8511;
4.7500    0.8495;
5.0000    0.8495]
figure
plot(net(:,1),net(:,2),'LineWidth',2,'LineStyle','--','Color','k')
hold on
plot(knn(:,1),knn(:,2),'LineWidth',2,'Color','k')
ylim([0 1])
xlabel('Minimum Duration of Not Epileptiform Activity For Termination (sec)')
ylabel('Accuracy of Detector to True Seizure Length')
legend({'Deep Learning Network','K Nearest Neighbor'})