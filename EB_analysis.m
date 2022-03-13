classdef EB_analysis
    % EB analaysis results of control and treatment brain with same
    % perivascular area and same extraction method
    properties
        segment_tbl
        n_px 
        UM_PX = 0.29288;    % constant
    end
    methods
        function obj = EB_analysis()
            % Construction of new EB_analysis object.
            [file1,folder1] = uigetfile('*.mat','Choose control analysis file');
            control = load(fullfile(folder1,file1));
            control_tbl = unpack_table(control.res.table);
            label = cell(height(control_tbl),1);
            label(:) = {'control'};
            control_tbl.label = label;
            [file2,folder2] = uigetfile('*.mat','Choose treatment analysis file');
            test = load(fullfile(folder2,file2));  
            test_tbl = unpack_table(test.res.table);
            label = cell(height(test_tbl),1);
            label(:) = {'test'};
            test_tbl.label = label;
            obj.segment_tbl = vertcat(control_tbl,test_tbl);
            obj.n_px = control.res.n_px;
            obj = obj.classify_opening;
        end
        function new_obj = subarea(obj,area_name)
            % Create new object with only sub area of the brain specified
            % as a string. example: new_obj = obj.subarea('hypothalamus');
            % Inputs:
            %   area_name (str)- string with the name of the ROI to be
            %       extracted
            new_obj = obj;
            area_idx = cellfun(@(x) contains(lower(x),lower(area_name)),...
                obj.segment_tbl.image_name);
            new_obj.segment_tbl(~area_idx,:) = [];
        end
        function new_obj = remove_outliers(obj,ths,varargin)
            % Create a new EB_analysis object where the data is cleaned from
            % outliers at each diameter group (test and control seperatly).
            % Simply applies rmoutliers() to the control and test groups at
            % each diameter.
            % Inputs:
            %    ths - diameter groups to be used for cleaning
            if nargin < 2
               ths = 2:15;
            end
            new_obj = obj;
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            control_tbl = obj.segment_tbl(control_idx,:);
            control_tbl = prettify_table(control_tbl,ths,varargin);
            test_tbl = obj.segment_tbl(~control_idx,:);
            test_tbl = prettify_table(test_tbl,ths,varargin);
            new_obj.segment_tbl = vertcat(control_tbl,test_tbl);
        end
        function new_obj = classify_opening(obj,ths,numstd)
            % Classify if a vessel was opened or not based on the red
            % intensity compared to the control intensity ditribution
            % Do it seperatly for every diameter group specified by ths
            % Inputs:
            %    ths - diameter groups to be used for classification
            %    numstd - number of standard deviationd from control avarage
            %        red intensity to use as opening threshold
            if nargin <3
                numstd = 3;
            end
            if nargin < 2
               ths = 2:15;
            end
            new_obj = obj;
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            [cont_eb_grouped,~] = ...
                intogroups(obj.segment_tbl.avg_red_px_val(control_idx),...
                obj.segment_tbl.median_segment_diam_um(control_idx),ths);
            cont_avs = cellfun(@(x) mean(x), cont_eb_grouped);
            cont_stds = cellfun(@(x) std(x), cont_eb_grouped);
            treat_th = cont_avs + numstd.*cont_stds; % Calculate the threshold
            % placeholder setup
            new_obj.segment_tbl.opening = ...
                zeros(height(new_obj.segment_tbl),1);
            ths = [0,ths];
            for i = 1:length(ths)-1
                new_obj.segment_tbl.opening(...
                    new_obj.segment_tbl.median_segment_diam_um >= ths(i) &...
                    new_obj.segment_tbl.median_segment_diam_um < ths(i+1) &...
                    ~control_idx &...
                    new_obj.segment_tbl.avg_red_px_val >= treat_th(i)) = 1;
            end
        end
        %% Plotting functions
        function scatterPlot(obj)
            % Simple scatter plot of all the vessel segments as 2D points 
            % in the diameter-extravasation plane
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            scatter(...
                obj.segment_tbl.median_segment_diam_um(control_idx),...
                obj.segment_tbl.avg_red_px_val(control_idx));
            hold on;
            scatter(...
                obj.segment_tbl.median_segment_diam_um(~control_idx),...
                obj.segment_tbl.avg_red_px_val(~control_idx));
            legend('control','treatment');
            title('extravasation as function of median diameter');
            xlabel('median segment diameter [um]'); 
            ylabel('Average red pixel intensity');
        end
        function fitplot(obj,fittype,ths)
            % line plot with two lines representing the control and test
            % samples in the diameter-extravasation plane, each line is
            % added with the error bars.
            % Inputs:
            %   fittype (optional)- fittype object to fit the data.
            %       specifing this will add the fitted equations to the plot.
            %       different fits can be specified to the control and test
            %       via a cell array of 1 x 2. example {'poly1','poly2'}
            %       will fit th control data with a linear equation and the
            %       test data with a quadratic equation.
            %   ths (optional)- array of diameters to be used as x-axis.
            %       vessels with diameter larger than ths(end) will not be
            %       presented.
            if nargin < 3
                ths = 1:15;
            end
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            [control_groups,~] = ...
                intogroups(obj.segment_tbl.avg_red_px_val(control_idx),...
                obj.segment_tbl.median_segment_diam_um(control_idx),ths);
            [test_groups,~] = ...
                intogroups(obj.segment_tbl.avg_red_px_val(~control_idx),...
                obj.segment_tbl.median_segment_diam_um(~control_idx),ths);
            test_red = cellfun(@(x) mean(x),test_groups);
            control_red = cellfun(@(x) mean(x),control_groups);
            test_red_std = cellfun(@(x) std(x),test_groups);
            control_red_std = cellfun(@(x) std(x),control_groups);
            errorbar(control_red,control_red_std,'b'); hold on;
            errorbar(test_red,test_red_std,'g');
            if nargin >= 2
                if isa(fittype,'char')
                    tmp = fittype;
                    fittype = cell(1,2); fittype(:) = cellstr(tmp);
                end
                control_median_diams = ...
                    obj.segment_tbl.median_segment_diam_um(control_idx);
                control_eb = ...
                    obj.segment_tbl.avg_red_px_val(control_idx);
                test_median_diams = ...
                    obj.segment_tbl.median_segment_diam_um(~control_idx);
                test_eb = ...
                    obj.segment_tbl.avg_red_px_val(~control_idx);
                [f1,gof1] = ...
                    fit(control_median_diams(control_median_diams >= ths(1) &...
                    control_median_diams <= ths(end)),...
                    control_eb(control_median_diams >= ths(1) &...
                    control_median_diams <= ths(end))...
                    ,fittype{1});
                [f2,gof2] = ...
                    fit(test_median_diams(test_median_diams >= ths(1) &...
                    test_median_diams <= ths(end)),...
                    test_eb(test_median_diams >= ths(1) &...
                    test_median_diams <= ths(end))...
                    ,fittype{2});
                plot(f1,'b--');
                plot(f2,'g--');
                legend('control','test',fitstr(f1,gof1),fitstr(f2,gof2));
            else
                legend('control','test');
            end
            xlabel('median segment diameter [um]'); 
            ylabel('Average red pixel intensity [8bit]');
        end
        function boxplot(obj,ths)
            % Box plot with 2 colors. one representing the control group
            % and the other representing the test group.
            % Inputs:
            %   ths (optional)- array of diameters to be used as x-axis.
            %       vessels with diameter larger than ths(end) will not be
            %       presented.
            if nargin < 2
                ths = 1:15;
            end
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            [median_control_eb,~] = ...
                intogroups(obj.segment_tbl.avg_red_px_val(control_idx),...
                obj.segment_tbl.median_segment_diam_um(control_idx),ths);
            [median_test_eb,~] = ...
                intogroups(obj.segment_tbl.avg_red_px_val(~control_idx),...
                obj.segment_tbl.median_segment_diam_um(~control_idx),ths);

            boxplot2(median_control_eb,'Colors','b','Positions',(ths-1).*20+10,...
                'Widths',5*ones(1,length(ths)+1));
            hold on;
            boxplot2(median_test_eb,'Colors','k','Positions',(ths-1).*20+15,...
                'Widths',5*ones(1,length(ths)+1));
            xticks((ths-1).*20+12.5);
            xticklabels(cellfun(@(x) num2str(x),num2cell(ths),'UniformOutput',false));

            title({'EB intensity in perivascular area as function of the vessel diameter',...
                [num2str(obj.n_px*obj.UM_PX),' um perivascular area']});

            ylabel('Average red pixel intensity');
        end
        function barplot(obj,ths,groups)
            % Bar plot with significance stars.
            % Inputs:
            %   ths (optional)- array of diameters to be used as x-axis.
            %       vessels with diameter larger than ths(end) will not be
            %       presented.
            %   groups - switch with 3 options for plotting:
            %       0 = plot the subtraction between test and control for
            %           each diameter
            %       1 = plot only the test group and calculate statistical
            %           significance bewteen each diameter and the smallest
            %           diameter
            %       2 = plot control and test and calculate statistical
            %           significance of difference between groups at each
            %           diameter seperatly
            if nargin < 3
                groups = 0;
            end
            if nargin < 2
                ths = 2:15;
            end
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            [control_groups,~] = ...
                intogroups(obj.segment_tbl.avg_red_px_val(control_idx),...
                obj.segment_tbl.median_segment_diam_um(control_idx),ths);
            [test_groups,~] = ...
                intogroups(obj.segment_tbl.avg_red_px_val(~control_idx),...
                obj.segment_tbl.median_segment_diam_um(~control_idx),ths);
            control_mu_median = cellfun(@(x) [mean(x);std(x)],...
                control_groups,'UniformOutput',false);
            control_mu_median = [control_mu_median{:}];
            test_mu_median = cellfun(@(x) [mean(x);std(x)],...
                test_groups,'UniformOutput',false);
            test_mu_median = [test_mu_median{:}];
            % remove outliers
            control_groups = cellfun(@(x) rmoutliers(x),control_groups,'UniformOutput',false);
            test_groups = cellfun(@(x) rmoutliers(x),test_groups,'UniformOutput',false);
            switch groups
                case 1  % only test
                    bar(1:2:(length(ths)*2+1),test_mu_median(1,:),0.5,'g');
                    hold on;
                    errorbar(1:2:(length(ths)*2+1),test_mu_median(1,:),...
                        test_mu_median(2,:),test_mu_median(2,:),'LineStyle','none'); 
                    xticks(1:2:(length(ths)*2+1));
                    xticklabels(cellfun(@(x) num2str(x),num2cell(ths),'UniformOutput',false));
                    title({'EB intensity in perivascular area as function of the vessel diameter',...
                        [num2str(obj.n_px*obj.UM_PX),' um perivascular area']});
                    xlabel('Vessel diameter [um]');
                    ylabel('Median red intensity in perivascular area [8bit]')

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
                case 2  % both groups
                    b1 =bar(0.75:2:(length(ths)*2+0.75),control_mu_median(1,:),0.25,'b');
                    hold on;
                    b2 =bar(1.25:2:(length(ths)*2+1.25),test_mu_median(1,:),0.25,'g');
                    errorbar(0.75:2:(length(ths)*2+0.75),control_mu_median(1,:),...
                        control_mu_median(2,:),control_mu_median(2,:),'LineStyle','none');
                    errorbar(1.25:2:(length(ths)*2+1.25),test_mu_median(1,:),...
                        test_mu_median(2,:),test_mu_median(2,:),'LineStyle','none'); 
                    xticks(1:2:(length(ths)*2+1));
                    xticklabels(cellfun(@(x) num2str(x),num2cell(ths),'UniformOutput',false));
                    title({'EB intensity in perivascular area as function of the vessel diameter',...
                        [num2str(obj.n_px*obj.UM_PX),' um perivascular area']});
                    xlabel('Vessel diameter [um]');
                    ylabel('Median red intensity in perivascular area [8bit]')

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
                case 0  % diffrence
                    bar(0.75:2:(length(ths)*2+0.75),...
                    test_mu_median(1,:)-control_mu_median(1,:),0.25,'b');
                    xticks(1:2:(length(ths)*2+1));
                    xticklabels(cellfun(@(x) num2str(x),num2cell(ths),'UniformOutput',false));
                    title({'test-control',...
                        [num2str(obj.n_px*obj.UM_PX),' um perivascular area']});
                    xlabel('Vessel diameter [um]');
                    ylabel('test-control difference in median red intensity [8bit]')
            end
        end
        function redDistrebution(obj,ths,numstd)
            % Plot the extravasation distribution of vesseles in control
            % and test groups groupd by their diameter.
            % Inputs:
            %   ths (optional)- array of diameters to be used as diameter ..
            %       groups.
            %   numstd (optional) - plot the threshold between control and
            %       test as mean + numstd*sigma
            if nargin < 2
                ths = [2:10,25];
            end
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            [control_groups,~] = ...
                intogroups(obj.segment_tbl.avg_red_px_val(control_idx),...
                obj.segment_tbl.median_segment_diam_um(control_idx),ths);
            [test_groups,~] = ...
                intogroups(obj.segment_tbl.avg_red_px_val(~control_idx),...
                obj.segment_tbl.median_segment_diam_um(~control_idx),ths);
            figure;
            len = numel(ths);
            ths = [0,ths];
            for i = 1:len
                subplot(ceil(sqrt(len)),ceil(sqrt(len)),i);
                histogram(control_groups{i},100); hold on;
                histogram(test_groups{i},100);
                xlim([0,155]);
                xlabel('Red channel median intensity in perivacular area');
                ylabel('Segment count');
                legend('control','test');
                if nargin == 3
                   controls = control_groups{i};
                   xline(mean(controls)+numstd*std(controls));
                   legend('control','test',...
                       ['Control mean +',num2str(numstd),'std']);
                end
                hold off; 
                title(sprintf('%d-%d um diameter',ths(i),ths(i+1)));
            end
        end
        function diamHist(obj)
            % histogram of blood vessel diameter. 
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            histogram(obj.segment_tbl.median_segment_diam_um(control_idx),...
                0.5:1:25.5); hold on;
            histogram(obj.segment_tbl.median_segment_diam_um(~control_idx),...
                0.5:1:25.5);
            legend('Control','Treatment');
            xlabel('Vessel diameter [um]'); ylabel('Count');
            xticks(1:25)
            title('Blood vessel diameter histogram'); 
        end
        function openedHist(obj,ths)
            % plot the histogram of fraction of opened vesseles by diameter
            % Inputs:
            %   ths - array of diameters to be used as diameter ..
            %       groups.
            if nargin < 2
               ths = 2:15;
            end
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            ths = [0, ths];
            len = length(ths)-1;
            perc = zeros(1,len);
            for i = 1:len
                in_group = ...
                    obj.segment_tbl.median_segment_diam_um >= ths(i) &...
                    obj.segment_tbl.median_segment_diam_um < ths(i+1) &...
                    ~control_idx;
                open_temp = in_group & obj.segment_tbl.opening;
                perc(i) = 100*(sum(open_temp)/sum(in_group));
            end
            bar(ths(2:end),perc,0.5,'g');
            xlabel('Vessel diameter [um]'); 
            ylabel('Open vessel fraction [%]');
            title('Opened vessel fraction as function of diameter'); 
        end
    end
end

%% Helper functions
function sfit = fitstr(f,gof)
% Create a label string for fit
sfit = ['y=',formula(f)];
vals = coeffvalues(f); names = coeffnames(f);
for i = 1:length(vals)
    sfit = strrep(sfit,names{i},num2str(vals(i)));
end
sfit = [sfit,' ; R^2=',num2str(gof.rsquare)];
end
function detailed_tbl = unpack_table(tbl)
% convert a packed table to a new table where every row represent a single
% vessel segment
lens = cellfun(@(x) length(x),tbl.median_segment_diam_um);
cumlens = cumsum(lens);
imname = cell(sum(lens),1);
for i = 1:height(tbl)
    if i == 1
        start_idx = 1;
    else
        start_idx = cumlens(i-1)+1;
    end
    end_idx = cumlens(i);
    imname(start_idx:end_idx) = tbl.image_name(i);
end
detailed_tbl = table(imname,vertcat(tbl.median_segment_diam_um{:,:}),...
    vertcat(tbl.avg_red_px_val{:,:}),'VariableNames',...
    {'image_name','median_segment_diam_um','avg_red_px_val'}); 
end
function pretty_tbl = prettify_table(tbl,ths,varargin)
% Get a table, sort it by the median vessel diameter, remove diameters
% larger than ths(end), and for each diameter group in ths remove the
% outliers.
pretty_tbl = tbl(tbl.median_segment_diam_um <= ths(end),:);
pretty_tbl = sortrows(pretty_tbl,'median_segment_diam_um');
ths = [0,ths];
if isempty(varargin{:}), varargin = 'median'; end
remove = true(height(pretty_tbl),1);
for i = 1:length(ths)-1  
    cur_range = ...
        find((pretty_tbl.median_segment_diam_um > ths(i)) &...
        (pretty_tbl.median_segment_diam_um <= ths(i+1)));
    cur_eb = pretty_tbl.avg_red_px_val(cur_range);
    [~,removed] = rmoutliers(cur_eb,varargin);
    remove(cur_range(1):cur_range(end)) = removed;
end
pretty_tbl(remove,:) = [];
end