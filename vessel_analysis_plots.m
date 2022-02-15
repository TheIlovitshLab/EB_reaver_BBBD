%This script creates plots [EB extravesation intensity vs vessel diameter]
%%
clc;clear;
% Define helper functions
col=@(x)reshape(x,numel(x),1);
boxplot2=@(C,varargin)boxplot(cell2mat(cellfun(col,col(C),'uni',0)),...
    cell2mat(arrayfun(@(I)I*ones(numel(C{I}),1),col(1:numel(C)),'uni',0)),varargin{:});

[file1,folder1] = uigetfile('*.mat','Choose control analysis file');
control = load(fullfile(folder1,file1));
[file2,folder2] = uigetfile('*.mat','Choose treatment analysis file');
test = load(fullfile(folder2,file2));

control_mean_diams = vertcat(control.res.table.mean_segment_diam_um{:,:});
control_median_diams = vertcat(control.res.table.median_segment_diam_um{:,:});
control_max_diams = vertcat(control.res.table.max_segment_diam_um{:,:});
control_eb = vertcat(control.res.table.avg_red_px_val{:,:});

test_mean_diams = vertcat(test.res.table.mean_segment_diam_um{:,:});
test_median_diams = vertcat(test.res.table.median_segment_diam_um{:,:});
test_max_diams = vertcat(test.res.table.max_segment_diam_um{:,:});
test_eb = vertcat(test.res.table.avg_red_px_val{:,:});
%% SCATTER PLOTS
figure; 
sgtitle(['Surrounding thickness: ',num2str(control.res.n_px),' [Px]']);
subplot(2,2,1);
scatter(control_mean_diams,control_eb);
hold on;
scatter(test_mean_diams,test_eb);
f_c_mean = fit(control_mean_diams,control_eb,'power2');
f_t_mean = fit(test_mean_diams,test_eb,'power2');
plot(f_c_mean,'g');
plot(f_t_mean,'r');
legend('control','treatment','fitted control','fitted treatment');
title('extravasation as function of mean diameter');
xlabel('mean segment diameter [um]'); ylabel('Average red pixel intensity');

subplot(2,2,2);
scatter(control_max_diams,control_eb);
hold on;
scatter(test_max_diams,test_eb);
f_c_max = fit(control_max_diams,control_eb,'power2');
f_t_max = fit(test_max_diams,test_eb,'power2');
plot(f_c_max,'g');
plot(f_t_max,'r');
legend('control','treatment','fitted control','fitted treatment');
title('extravasation as function of max diameter');
xlabel('Max segment diameter [um]'); ylabel('Average red pixel intensity');

subplot(2,2,[3,4]);
scatter(control_median_diams,control_eb);
hold on;
scatter(test_median_diams,test_eb);
f_c_median = fit(control_median_diams,control_eb,'power2');
f_t_median = fit(test_median_diams,test_eb,'power2');
plot(f_c_median,'g');
plot(f_t_median,'r');
legend('control','treatment','fitted control','fitted treatment');
title('extravasation as function of median diameter');
xlabel('median segment diameter [um]'); ylabel('Average red pixel intensity');
%% box plot
sgtitle(['Surrounding thickness: ',num2str(control.res.n_px),' [Px]']);
ths = [5,9];
mean_control_eb = intogroups(control_eb,control_mean_diams,ths);
mean_test_eb = intogroups(test_eb,test_mean_diams,ths);
max_control_eb = intogroups(control_eb,control_max_diams,ths);
max_test_eb = intogroups(test_eb,test_max_diams,ths);
median_control_eb = intogroups(control_eb,control_median_diams,ths);
median_test_eb = intogroups(test_eb,test_median_diams,ths);

subplot(2,2,3,'align')
boxplot2(mean_control_eb,'Colors','b','Positions',[10,30,50],...
    'Widths',[5,5,5]);
hold on;
boxplot2(mean_test_eb,'Colors','k','Positions',[15,35,55],...
    'Widths',[5,5,5]);
xticks([12.5,32.5,52.5]);
xticklabels({['<',num2str(ths(1)),'[um]'],...
    [num2str(ths(1)),'[um]< <',num2str(ths(2)),'[um]'],...
    [num2str(ths(2)),'[um]<']})
title('extravasation as function of mean diameter');
ylabel('Average red pixel intensity');

subplot(2,2,4);
boxplot2(max_control_eb,'Colors','b','Positions',[10,30,50],...
    'Widths',[5,5,5]);
hold on;
boxplot2(max_test_eb,'Colors','k','Positions',[15,35,55],...
    'Widths',[5,5,5]);
xticks([12.5,32.5,52.5]);
xticklabels({['<',num2str(ths(1)),'[um]'],...
    [num2str(ths(1)),'[um]<diam<',num2str(ths(2)),'[um]'],...
    [num2str(ths(2)),'[um]<']})
title('extravasation as function of max diameter');
ylabel('Average red pixel intensity');

subplot(2,2,[1,2]);
boxplot2(median_control_eb,'Colors','b','Positions',[10,30,50],...
    'Widths',[5,5,5]);
hold on;
boxplot2(median_test_eb,'Colors','k','Positions',[15,35,55],...
    'Widths',[5,5,5]);
xticks([12.5,32.5,52.5]);
xticklabels({['<',num2str(ths(1)),'[um]'],...
    [num2str(ths(1)),'[um]<diam<',num2str(ths(2)),'[um]'],...
    [num2str(ths(2)),'[um]<']})
title('extravasation as function of median diameter');
ylabel('Average red pixel intensity');
%% Bar plot

ths = [3,9];
control_groups_mean = intogroups(control_eb,control_mean_diams,ths);
control_mu_mean = cellfun(@(x) [mean(x);std(x)],control_groups_mean,...
    'UniformOutput',false);
control_mu_mean = [control_mu_mean{:}];

test_groups_mean = intogroups(test_eb,test_mean_diams,ths);
test_mu_mean = cellfun(@(x) [mean(x);std(x)],...
    test_groups_mean,'UniformOutput',false);
test_mu_mean = [test_mu_mean{:}];

control_mu_median = cellfun(@(x) [mean(x);std(x)],...
    intogroups(control_eb,control_median_diams,ths),'UniformOutput',false);
control_mu_median = [control_mu_median{:}];
test_mu_median = cellfun(@(x) [mean(x);std(x)],...
    intogroups(test_eb,test_median_diams,ths),'UniformOutput',false);
test_mu_median = [test_mu_median{:}];

control_mu_max = cellfun(@(x) [mean(x);std(x)],...
    intogroups(control_eb,control_max_diams,ths),'UniformOutput',false);
control_mu_max = [control_mu_max{:}];
test_mu_max = cellfun(@(x) [mean(x);std(x)],...
    intogroups(test_eb,test_max_diams,ths),'UniformOutput',false);
test_mu_max = [test_mu_max{:}];

figure;
% sgtitle(['Surrounding thickness: ',num2str(control.res.n_px),' [Px]']);

% subplot(1,2,1);
b1 =bar(0.75:2:4.75,control_mu_median(1,:),0.25,'b');
hold on;
b2 =bar(1.25:2:5.25,test_mu_median(1,:),0.25,'g');
legend('control','treatment');
errorbar(0.75:2:4.75,control_mu_median(1,:),...
    control_mu_median(2,:),control_mu_median(2,:),'LineStyle','none');
errorbar(1.25:2:5.25,test_mu_median(1,:),...
    test_mu_median(2,:),test_mu_median(2,:),'LineStyle','none'); 
legend([b1,b2],'control','treatment');
xticks([1,3,5]);
xticklabels({['<',num2str(ths(1)),'[um]'],...
    [num2str(ths(1)),'[um]<diam<',num2str(ths(2)),'[um]'],...
    [num2str(ths(2)),'[um]<']})
title('extravasation as function of median diameter');

% subplot(1,2,2);
% b1 = bar(0.75:2:4.75,control_mu_max(1,:),0.25,'b');
% hold on;
% b2 = bar(1.25:2:5.25,test_mu_max(1,:),0.25,'g');
% legend('control','treatment');
% errorbar(0.75:2:4.75,control_mu_max(1,:),...
%     control_mu_max(2,:),control_mu_max(2,:),'LineStyle','none');
% errorbar(1.25:2:5.25,test_mu_max(1,:),...
%     test_mu_max(2,:),test_mu_max(2,:),'LineStyle','none'); 
% legend([b1,b2],'control','treatment');
% xticks([1,3,5]);
% xticklabels({['<',num2str(ths(1)),'[um]'],...
%     [num2str(ths(1)),'[um]<diam<',num2str(ths(2)),'[um]'],...
%     [num2str(ths(2)),'[um]<']})
% title('extravasation as function of max diameter');

