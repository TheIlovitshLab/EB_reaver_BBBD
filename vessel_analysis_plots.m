%This script creates plots [EB extravesation intensity vs vessel diameter]
%%
clc;clear;
% Define helper functions
um_px = 0.29288;    % constant

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

scatter(control_median_diams,control_eb);
hold on;
scatter(test_median_diams,test_eb);
legend('control','treatment');
title('extravasation as function of median diameter');
xlabel('median segment diameter [um]'); ylabel('Average red pixel intensity');
%% box plot
ths = 1:15;

median_control_eb = intogroups(control_eb,control_median_diams,ths);
median_test_eb = intogroups(test_eb,test_median_diams,ths);

boxplot2(median_control_eb,'Colors','b','Positions',(ths-1).*20+10,...
    'Widths',5*ones(1,length(ths)+1));
hold on;
boxplot2(median_test_eb,'Colors','k','Positions',(ths-1).*20+15,...
    'Widths',5*ones(1,length(ths)+1));
xticks((ths-1).*20+12.5);
xticklabels(cellfun(@(x) num2str(x),num2cell(ths),'UniformOutput',false));

title({'EB intensity in perivascular area as function of the vessel diameter',...
    [num2str(control.res.n_px*um_px),' um perivascular area']});

ylabel('Average red pixel intensity');
%% Bar plot

ths = 1:15;
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


figure;

b1 =bar(0.75:2:(length(ths)*2+0.75),control_mu_median(1,:),0.25,'b');
hold on;
b2 =bar(1.25:2:(length(ths)*2+1.25),test_mu_median(1,:),0.25,'g');
legend('control','treatment');
errorbar(0.75:2:(length(ths)*2+0.75),control_mu_median(1,:),...
    control_mu_median(2,:),control_mu_median(2,:),'LineStyle','none');
errorbar(1.25:2:(length(ths)*2+1.25),test_mu_median(1,:),...
    test_mu_median(2,:),test_mu_median(2,:),'LineStyle','none'); 
legend([b1,b2],'control','treatment');
xticks(ths.*2-1);
xticklabels(cellfun(@(x) num2str(x),num2cell(ths),'UniformOutput',false));
title({'EB intensity in perivascular area as function of the vessel diameter',...
    [num2str(control.res.n_px*um_px),' um perivascular area']});
xlabel('Vessel diameter [um]');
ylabel('Median red intensity in perivascular area [16bit]')

