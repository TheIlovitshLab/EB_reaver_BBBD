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

plt = scatter(control_median_diams,control_eb);
hold on;
scatter(plt,test_median_diams,test_eb);
legend(plt,'control','treatment');
title(plt,'extravasation as function of median diameter');
xlabel(plt,'median segment diameter [um]'); ylabel('Average red pixel intensity');
%% box plot
ths = 2:15;
figure;
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
%% Bar plot control vs test
ths = 2:15;

control_groups = intogroups(control_eb,control_median_diams,ths);
test_groups = intogroups(test_eb,test_median_diams,ths);
control_mu_median = cellfun(@(x) [mean(x);std(x)],...
    control_groups,'UniformOutput',false);
control_mu_median = [control_mu_median{:}];
test_mu_median = cellfun(@(x) [mean(x);std(x)],...
    test_groups,'UniformOutput',false);
test_mu_median = [test_mu_median{:}];
% remove outliers
control_groups = cellfun(@(x) rmoutliers(x),control_groups,'UniformOutput',false);
test_groups = cellfun(@(x) rmoutliers(x),test_groups,'UniformOutput',false);


figure;

b1 =bar(0.75:2:(length(ths)*2+0.75),control_mu_median(1,:),0.25,'b');
hold on;
b2 =bar(1.25:2:(length(ths)*2+1.25),test_mu_median(1,:),0.25,'g');
errorbar(0.75:2:(length(ths)*2+0.75),control_mu_median(1,:),...
    control_mu_median(2,:),control_mu_median(2,:),'LineStyle','none');
errorbar(1.25:2:(length(ths)*2+1.25),test_mu_median(1,:),...
    test_mu_median(2,:),test_mu_median(2,:),'LineStyle','none'); 
xticks(ths.*2-1);
xticklabels(cellfun(@(x) num2str(x),num2cell(ths),'UniformOutput',false));
title({'EB intensity in perivascular area as function of the vessel diameter',...
    [num2str(control.res.n_px*um_px),' um perivascular area']});
xlabel('Vessel diameter [um]');
ylabel('Median red intensity in perivascular area [16bit]')

% Add significance stars of control vs test of same diameter
for i = 1:length(ths)
   [~,p] = ttest2(control_groups{i},test_groups{i});
   maxy = max([sum(control_mu_median(:,i)),sum(test_mu_median(:,i))]);
   x_cord = ths(i)-ths(1);
   line([0.5,1.5]+x_cord*2,(maxy*1.05)*[1,1]);
   if p<=10^-4
       text(x_cord*2+0.5,maxy*1.08,'****');
   elseif p <=10^-3
       text(x_cord*2+0.5,maxy*1.08,'***');
   elseif p <=10^-2
       text(x_cord*2+0.5,maxy*1.08,'**');
   elseif p <=0.05
       text(x_cord*2+0.5,maxy*1.08,'*');
   else
       text(x_cord*2+0.5,maxy*1.12,'ns');
   end
end
legend([b1,b2],'control','treatment');
%% Only test bar plot
ths = 2:15;
test_groups = intogroups(test_eb,test_median_diams,ths);
test_mu_median = cellfun(@(x) [mean(x);std(x)],...
    test_groups,'UniformOutput',false);
test_mu_median = [test_mu_median{:}];


figure;
b2 =bar(1:2:(length(ths)*2+1),test_mu_median(1,:),0.5,'g');
hold on;
errorbar(1:2:(length(ths)*2+1),test_mu_median(1,:),...
    test_mu_median(2,:),test_mu_median(2,:),'LineStyle','none'); 
xticks(ths.*2-1);
xticklabels(cellfun(@(x) num2str(x),num2cell(ths),'UniformOutput',false));
title({'EB intensity in perivascular area as function of the vessel diameter',...
    [num2str(control.res.n_px*um_px),' um perivascular area']});
xlabel('Vessel diameter [um]');
ylabel('Median red intensity in perivascular area [16bit]')

for i = ths(2:end)
   [~,p] = ttest2(test_groups{1},test_groups{i});
   maxy = max(sum(test_mu_median,1))*(0.5+i/20);
   dy = max(sum(test_mu_median,1))*0.01;
   line([0.5,(i-1)*2+1.5],maxy*[1,1]);
   if p<=10^-4
       text((i-1)*2+1.5,maxy*1.01,'****');
   elseif p <=10^-3
       text((i-1)*2+1.5,maxy*1.01,'***');
   elseif p <=10^-2
       text((i-1)*2+1.5,maxy*1.01,'**');
   elseif p <=0.05
       text((i-1)*2+1.5,maxy*1.01,'*');
   else
       text((i-1)*2+1.5,maxy*1.01+dy,'ns');
   end
end
%% Reduced mean bar plot
ths = 2:15;

control_groups = intogroups(control_eb,control_median_diams,ths);
test_groups = intogroups(test_eb,test_median_diams,ths);
control_mu_median = cellfun(@(x) [mean(x);std(x)],...
    control_groups,'UniformOutput',false);
control_mu_median = [control_mu_median{:}];
test_mu_median = cellfun(@(x) [mean(x);std(x)],...
    test_groups,'UniformOutput',false);
test_mu_median = [test_mu_median{:}];

b1 =bar(0.75:2:(length(ths)*2+0.75),...
    test_mu_median(1,:)-control_mu_median(1,:),0.25,'b');
xticks(ths.*2-1);
xticklabels(cellfun(@(x) num2str(x),num2cell(ths),'UniformOutput',false));
title({'test-control',...
    [num2str(control.res.n_px*um_px),' um perivascular area']});
xlabel('Vessel diameter [um]');
ylabel('test-control difference in median red intensity [16bit]')
%% test and control red histograms by diameter
ths = [2:10,25];

control_groups = intogroups(control_eb,control_median_diams,ths);
test_groups = intogroups(test_eb,test_median_diams,ths);
figure;
for i = 1:numel(ths)
    subplot(ceil(sqrt(numel(ths))),ceil(sqrt(numel(ths))),i);
    histogram(control_groups{i},100); hold on; histogram(test_groups{i},100);
    hold off; legend('control','test');
    title(num2str(ths(i)));
end
%% Blood vessel diameter histogram
figure;
histogram(control_median_diams,0.5:1:25.5); hold on;
histogram(test_median_diams,0.5:1:25.5);
legend('Control','Treatment');
xlabel('Vessel diameter [um]'); ylabel('Count');
xticks(1:25)
title('Blood vessel diameter histogram');

%% Colocalization stats
control_r = colocalization_stats(folder1);
test_r = colocalization_stats(folder2);
figure;
boxplot2({control_r;test_r});
xticklabels({'control','test'}); 
ylabel('Pearson correlation between red and green channel');
title('Pearson correlation score');
[h,p] = ttest2(control_r,test_r);
maxy = max(test_r)*1.01;
dy = maxy*0.01;
if p<=10^-4
   text(2,maxy*1.01,'****','HorizontalAlignment','center');
elseif p <=10^-3
   text(2,maxy*1.01,'***','HorizontalAlignment','center');
elseif p <=10^-2
   text(2,maxy*1.01,'**','HorizontalAlignment','center');
elseif p <=0.05
   text(2,maxy*1.01,'*','HorizontalAlignment','center');
else
   text(2,maxy*1.01+dy,'ns','HorizontalAlignment','center');
end