classdef EB_analysis
    % EB analaysis results of control and treatment brain sections
    properties
        segment_tbl
        n_px
        from_px
        UM_PX    
    end
    methods
        function obj = EB_analysis(control_file,test_file,um_px)
            % Construction of new EB_analysis object.
            % Input arguements:
            %   control = control EB_analysis_entire folder file
            %   Test = test EB_analysis_entire folder file
            %   um_px = ratio of microns to pixel
            if nargin < 1
                [file1,folder1] = uigetfile('*.mat','Choose control analysis file');
                control_file = fullfile(folder1,file1);
            end
            control = load(control_file);
            if nargin < 2
                [file2,folder2] = uigetfile('*.mat','Choose treatment analysis file');
                test_file = fullfile(folder2,file2);
            end
            test = load(test_file);
            control_tbl = unpack_table(control.res.table);
            label = cell(height(control_tbl),1);
            label(:) = {'control'};
            control_tbl.label = label;
            test_tbl = unpack_table(test.res.table);
            label = cell(height(test_tbl),1);
            label(:) = {'test'};
            test_tbl.label = label;
            obj.segment_tbl = vertcat(control_tbl,test_tbl);
            obj.n_px = control.res.n_px;
            obj.from_px = control.res.from_px;
            obj = obj.classify_opening;
            if nargin < 3
                obj.UM_PX = 0.29288;    % Default
            else
                obj.UM_PX = um_px;
            end
        end
        function [new_obj_sub, new_obj_exc]  = subarea(obj,area_name)
            % Create new object with only sub area of the brain specified
            % as a string. example: new_obj = obj.subarea('hypothalamus');
            % Inputs:
            %   area_name (str)- string with the name of the ROI to be
            %       extracted
            area_idx = cellfun(@(x) contains(lower(x),lower(area_name)),...
                obj.segment_tbl.image_name);
            new_obj_sub = obj;
            new_obj_sub.segment_tbl(~area_idx,:) = [];
            new_obj_exc = obj;
            new_obj_exc.segment_tbl(area_idx,:) = [];
        end
        function writecsv(obj,ths,GroupByFrame,control_csv_filename,test_csv_filename)
            % save control and test data to csv in a graphpad format
            % Ths = diameter grouop edges
            % GroupByFrame = boolean flag            
            if nargin < 2
                ths = 2:10;
            end
            if nargin < 3
                GroupByFrame = 0;
            end
            if nargin < 4
                [control_csv_filename, control_csv_folder] = ...
                    uiputfile({'*.csv';'*.xlsx'},'Specify control csv file name');
                control_csv_filename = ...
                    fullfile(control_csv_folder,control_csv_filename);
                [test_csv_filename, test_csv_folder] = ...
                    uiputfile({'*.csv';'*.xlsx'},'Specify test csv file name');
                test_csv_filename = ...
                    fullfile(test_csv_folder, test_csv_filename);
            end
            control_idx = cellfun(@(x) strcmp(x,'control'),obj.segment_tbl.label);
            n_bins = numel(ths);
            control_discrete_cell = intogroups(...
                obj.segment_tbl(control_idx,:),ths,GroupByFrame);
            test_discrete_cell = intogroups(...
                obj.segment_tbl(~control_idx,:),ths,GroupByFrame);
            str_cell = cell(n_bins-1,1);
            ths = [0,ths];
            for i = 1:n_bins
                str_cell{i} = sprintf('%d - %d',ths(i),ths(i+1));
            end
            control_tbl = cell2table(...
                [str_cell,control_discrete_cell],...
                'VariableNames',{'Diameter','red intensity'});
            test_tbl = cell2table(...
                [str_cell,test_discrete_cell],...
                'VariableNames',{'Diameter','red intensity'});
            writetable(control_tbl, control_csv_filename);
            writetable(test_tbl, test_csv_filename);
        end
        function new_obj = keep_diameters(obj,lowLim,highLim)
           % Remove all vessel segments outside the given diameter range
           new_obj = obj;
           new_obj.segment_tbl(...
               (obj.segment_tbl.median_segment_diam_um < lowLim) |...
               (obj.segment_tbl.median_segment_diam_um > highLim),:) = [];
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
            cont_eb_grouped = ...
                intogroups(obj.segment_tbl(control_idx,:),ths);
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
                    new_obj.segment_tbl.median_red >= treat_th(i)) = 1;
            end
        end
        function new_obj = match_histograms(obj)
           % At each diameter group, remove the outliers from one of the 
           % conditions (Conrtol/Test) to have equal number of vessel
           % segments in both conditions.
           control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
           ths = unique(ceil(obj.segment_tbl.median_segment_diam_um));
           ths = [0,ths'];
           new_obj = obj;
           rm_rows = [];
           for i = 1:length(ths)-1
               cur_control = new_obj.segment_tbl.median_red(...
                   new_obj.segment_tbl.median_segment_diam_um >= ths(i) &...
                   new_obj.segment_tbl.median_segment_diam_um < ths(i+1) &...
                   control_idx);
               cur_test = new_obj.segment_tbl.median_red(...
                   new_obj.segment_tbl.median_segment_diam_um >= ths(i) &...
                   new_obj.segment_tbl.median_segment_diam_um < ths(i+1) &...
                   ~control_idx); 
               if numel(cur_control) > numel(cur_test)
                   n_outliers = numel(cur_control)-numel(cur_test);
                   [~,intensity_idx] = ...
                       sort(abs(cur_control-mean(cur_control)));
                   control_rows = find(control_idx);
                   rm_rows = [rm_rows;...
                       control_rows(intensity_idx(1:n_outliers))];
               else
                   n_outliers = numel(cur_test)-numel(cur_control);
                   [~,intensity_idx] = ...
                       sort(abs(cur_test-mean(cur_test)));
                   test_rows = find(~control_idx);
                   rm_rows = [rm_rows;...
                       test_rows(intensity_idx(1:n_outliers))];
               end
           end
           new_obj.segment_tbl(rm_rows,:) = [];
        end
        
        %% Plotting functions
        function scatterPlot(obj)
            % Simple scatter plot of all the vessel segments as 2D points 
            % in the diameter-extravasation plane
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            scatter(...
                obj.segment_tbl.median_segment_diam_um(control_idx),...
                obj.segment_tbl.median_red(control_idx));
%                             'c','#8c1515'
            hold on;
            scatter(...
                obj.segment_tbl.median_segment_diam_um(~control_idx),...
                obj.segment_tbl.median_red(~control_idx));
%                 'c','#09425A');
            legend('control','MB + FUS');
            title(sprintf('[%d,%d] px',...
                obj.from_px,obj.from_px+obj.n_px));
            xlabel('median segment diameter [um]'); 
            ylabel('Median red pixel intensity [A.U.]');
        end
        function fitplot(obj,ths, fitType)
            % line plot with two lines representing the control and test
            % samples in the diameter-extravasation plane, each line is
            % added with the error bars.
            % Inputs:
            %   ths (optional)- array of diameters to be used as x-axis.
            %       vessels with diameter larger than ths(end) will not be
            %       presented.
            %   fitType (optional)- fittype object to fit the data.
            %       specifing this will add the fitted equations to the plot.
            %       different fits can be specified to the control and test
            %       via a cell array of 1 x 2. example {'poly1','poly2'}
            %       will fit th control data with a linear equation and the
            %       test data with a quadratic equation.
            if nargin < 2
                ths = 2:10;
            end
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            control_groups = ...
                intogroups(obj.segment_tbl(control_idx,:),ths);
            test_groups = ...
                intogroups(obj.segment_tbl(~control_idx,:),ths);
            test_red = cellfun(@(x) mean(x),test_groups);
            control_red = cellfun(@(x) mean(x),control_groups);
            test_red_std = cellfun(@(x) std(x),test_groups);
            control_red_std = cellfun(@(x) std(x),control_groups);
            errorbar(control_red,control_red_std,'Color','#8c1515');...
                hold on; errorbar(test_red,test_red_std,'Color','#09425A');
            if nargin >= 2
                if isa(fitType,'char')  % if user specified a single fitType object for both groups
                    tmp = fitType;
                    fitType = cell(1,2); fitType(:) = cellstr(tmp);
                end
                control_median_diams = ...
                    obj.segment_tbl.median_segment_diam_um(control_idx);
                control_eb = ...
                    obj.segment_tbl.median_red(control_idx);
                test_median_diams = ...
                    obj.segment_tbl.median_segment_diam_um(~control_idx);
                test_eb = ...
                    obj.segment_tbl.median_red(~control_idx);
                [f1,gof1] = ...
                    fit(control_median_diams(control_median_diams >= ths(1) &...
                    control_median_diams <= ths(end)),...
                    control_eb(control_median_diams >= ths(1) &...
                    control_median_diams <= ths(end))...
                    ,fitType{1});
                [f2,gof2] = ...
                    fit(test_median_diams(test_median_diams >= ths(1) &...
                    test_median_diams <= ths(end)),...
                    test_eb(test_median_diams >= ths(1) &...
                    test_median_diams <= ths(end))...
                    ,fitType{2});
                plot(f1)
                plot(f2)
                h= get(gca, 'Children');
                set(h(2),'Color','#8c1515', 'LineStyle','--');
                set(h(1),'Color','#09425A', 'LineStyle','--');
                legend('control','test',...
                    strrep(fitstr(f1,gof1),'y','y(control)'),...
                    strrep(fitstr(f2,gof2),'y','y(MB+FUS)'));
            else
                legend('control','MB + FUS');
            end
            xlabel('median segment diameter [um]'); 
            ylabel('Median red pixel intensity [A.U.]');
        end
        function violinplot(obj,ths,varargin)
            % Implementation of violin plot
            % Inputs:
            %   ths (optional)- array of diameters to be used as x-axis.
            %       vessels with diameter larger than ths(end) will not be
            %       presented. if ths not specified a single violin will be
            %       plotted for all vessel diameters
            %   varargin - input arguements of the varargin function by
            %       B. Bechtold
            %       (https://github.com/bastibe/Violinplot-Matlab)
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            figure;
            if nargin < 2   % No diameter thresholds specified
                control_groups = ...
                    obj.segment_tbl.median_red(control_idx);
                test_groups = ...
                    obj.segment_tbl.median_red(~control_idx);
                control_groups = rmoutliers(control_groups);
                test_groups = rmoutliers(test_groups);
                Violin({control_groups},1,...
                    'HalfViolin','left','ViolinColor',{[1,0,0]},...
                    varargin{:});
                hold on;
                Violin({test_groups},1,...
                    'HalfViolin','right','ViolinColor',{[0,0,1]},...
                    varargin{:});
                xticks([]);
                hold off;
            else
                control_groups = ...
                    intogroups(obj.segment_tbl(control_idx,:),ths);
                test_groups = ...
                    intogroups(obj.segment_tbl(~control_idx,:),ths);
                % remove outliers
                control_groups = cellfun(@(x) rmoutliers(x),...
                    control_groups,'UniformOutput',false);
                test_groups = cellfun(@(x) rmoutliers(x),...
                    test_groups,'UniformOutput',false);
                for i = 1:numel(control_groups)
                    Violin(control_groups(i),i,...
                        'HalfViolin','left','ViolinColor',{[1,0,0]});
                    hold on;
                end
                for i = 1:numel(test_groups)
                    Violin(test_groups(i),i,...
                        'HalfViolin','right','ViolinColor',{[0,0,1]});
                    hold on;
                end
                xticks([1:numel(control_groups)]);
                xticklabels(generate_xticks(ths));
                xlabel('Diameter [um]');
                hold off;
            end
            ylabel('Median red intensity in perivscular area [A.U.]');
            ax = gca;
            ch = get(ax,'Children');
            red_envalope = ch(end-1);
            blue_envalope = ch(7);
            legend([red_envalope,blue_envalope],{'control','MB + FUS'})
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
            %       -1 = plot only the control group and calculate statistical
            %           significance bewteen each diameter and the smallest
            %           diameter
            if nargin < 3
                groups = 2;
            end
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            if nargin < 2   % No diameter thresholds specified
                control_groups = ...
                    obj.segment_tbl.median_red(control_idx);
                test_groups = ...
                    obj.segment_tbl.median_red(~control_idx);
                control_mu_median = [mean(control_groups);
                    std(control_groups)];
                test_mu_median = [mean(test_groups);
                    std(test_groups)];
                control_groups = rmoutliers(control_groups);
                test_groups = rmoutliers(test_groups);
                ths = 0;
            else
                control_groups = ...
                    intogroups(obj.segment_tbl(control_idx,:),ths);
                test_groups = ...
                    intogroups(obj.segment_tbl(~control_idx,:),ths);
                control_mu_median = cellfun(@(x) [mean(x);std(x)],...
                    control_groups,'UniformOutput',false);
                control_mu_median = [control_mu_median{:}];
                test_mu_median = cellfun(@(x) [mean(x);std(x)],...
                    test_groups,'UniformOutput',false);
                test_mu_median = [test_mu_median{:}];
                % remove outliers
                control_groups = cellfun(@(x) rmoutliers(x),...
                    control_groups,'UniformOutput',false);
                test_groups = cellfun(@(x) rmoutliers(x),...
                    test_groups,'UniformOutput',false);
            end
            switch groups
                case 1  % only test
                    bar(1:2:(length(ths)*2),test_mu_median(1,:),0.5,...
                        'FaceColor','#09425A');
                    hold on;
                    errorbar(1:2:(length(ths)*2),test_mu_median(1,:),...
                        test_mu_median(2,:),test_mu_median(2,:),...
                        'LineStyle','none'); 
                    xticks(1:2:(length(ths)*2));
                    xticklabels(generate_xticks(ths));
                    title(sprintf('[%d,%d] px]',...
                        obj.from_px,obj.from_px+obj.n_px));
                    xlabel('Vessel diameter [um]');
                    ylabel('Median red intensity in perivascular area [A.U.]')

                    for i = 2:numel(ths)
                       [~,p] = ttest2(test_groups{i-1},test_groups{i});
                       st = sigstars(p);
                       if ~strcmp(st,'ns')
                           maxy = max(sum(test_mu_median(1:2,:),1))*(1+i/20);
                           line([(i-1)*2,(i+1)*2],maxy*[1,1]);
                           pos = (i-1)*2+1.5-length(st)*0.25;
                           y_pos = maxy*1.01;
                           text(pos,y_pos,st);
                       end
                    end
                case 2  % both groups
                    if length(ths) == 1
                        b1 = bar(0.75,control_mu_median(1,:),0.25,...
                            'FaceColor','#8c1515');
                        hold on;
                        b2 =bar(1.25,test_mu_median(1,:),0.25,...
                            'FaceColor','#09425A');
                        errorbar(0.75,control_mu_median(1,:),...
                            control_mu_median(2,:),control_mu_median(2,:),...
                            'k', 'LineStyle','none');
                        errorbar(1.25,test_mu_median(1,:),...
                            test_mu_median(2,:),test_mu_median(2,:),'k',...
                            'LineStyle','none'); 
                        xticks([]);
                        % Add significance stars of control vs test of same diameter
                       [~,p] = ttest2(control_groups,test_groups);
                       maxy = max([sum(control_mu_median),...
                           sum(test_mu_median)]);
                       line([0.5,1.5],(maxy*1.05)*[1,1]);
                       text(0.5,maxy*1.08,sigstars(p));
                    else
                        b1 = bar(0.75:2:(length(ths)*2),...
                            control_mu_median(1,:),0.25,...
                            'FaceColor','#8c1515');
                        hold on;
                        b2 =bar(1.25:2:(length(ths)*2),...
                            test_mu_median(1,:),0.25,...
                            'FaceColor','#09425A');
                        errorbar(0.75:2:(length(ths)*2),control_mu_median(1,:),...
                            control_mu_median(2,:),control_mu_median(2,:),'k',...
                            'LineStyle','none');
                        errorbar(1.25:2:(length(ths)*2),test_mu_median(1,:),...
                            test_mu_median(2,:),test_mu_median(2,:),'k',...
                            'LineStyle','none'); 
                        xticks(1:2:(length(ths)*2));
                        xticklabels(generate_xticks(ths));
                        xlabel('Vessel diameter [um]');
                        % Add significance stars of control vs test of same diameter
                        for i = 1:length(ths)
                           [~,p] = ttest2(control_groups{i},test_groups{i});
                           maxy = max([sum(control_mu_median(:,i)),sum(test_mu_median(:,i))]);
                           x_cord = i-1;
                           line([0.5,1.5]+x_cord*2,(maxy*1.05)*[1,1]);
                           text(x_cord*2+0.5,maxy*1.08,sigstars(p));
                        end
                    end
                    ylim([0,maxy*1.1]);
                    legend([b1,b2],'control','MB + FUS');
                    title(sprintf('[%d,%d] px]',...
                        obj.from_px,obj.from_px+obj.n_px));
                    ylabel('Median red intensity in perivascular area [A.U.]')
                case 0  % diffrence
                    bar(0.75:2:(length(ths)*2+0.75),...
                    test_mu_median(1,:)-control_mu_median(1,:),0.25,...
                    'FaceColor','#09425A');
                    xticks(1:2:(length(ths)*2+1));
                    xticklabels(generate_xticks(ths));
                    title({'treatment-control',...
                        [num2str(obj.n_px*obj.UM_PX),' um perivascular area']});
                    xlabel('Vessel diameter [um]');
                    ylabel('test-control difference in Median red intensity [A.U.]')
                case -1  % only control
                    bar(1:2:(length(ths)*2),control_mu_median(1,:),0.5,...
                        'FaceColor','#8c1515');
                    hold on;
                    errorbar(1:2:(length(ths)*2),control_mu_median(1,:),...
                        control_mu_median(2,:),control_mu_median(2,:),...
                        'LineStyle','none'); 
                    xticks(1:2:(length(ths)*2));
                    xticklabels(generate_xticks(ths));
                    title({['EB intensity in perivascular area',...
                        ' as function of the vessel diameter'],...
                        [num2str(obj.n_px*obj.UM_PX),' um perivascular area']});
                    xlabel('Vessel diameter [um]');
                    ylabel('Median red intensity in perivascular area [A.U.]')

                    for i = 2:numel(ths)
                       [~,p] = ttest2(control_groups{i-1},control_groups{i});
                       st = sigstars(p);
                       if ~strcmp(st,'ns')
                           maxy = max(sum(test_mu_median(1:2,:),1))*(1+i/20);
                           line([(i-1)*2,(i+1)*2],maxy*[1,1]);
                           pos = (i-1)*2+1.5-length(st)*0.25;
                           y_pos = maxy*1.01;
                           text(pos,y_pos,st);
                       end
                    end
            end
        end
        function redDistrebution(obj,ths,numstd,varargin)
            % Plot the extravasation distribution of vesseles in control
            % and test groups groupd by their diameter.
            % Inputs:
            %   ths (optional)- array of diameters to be used as diameter ..
            %       groups.
            %   numstd (optional) - plot the threshold between control and
            %       test as mean + numstd*sigma
            % Name-Value pair arguements:
            %   'Mode' (optional) - display mode, can either be 'histogram'
            %       (default) or 'pdf' which displys the kernel density
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            P = inputParser();
            P.addOptional('ths',[],@(x) isnumeric(x));
            P.addOptional('numstd',[],@(x) isa(x,'double'));
            P.addParameter('Mode','histogram',...
                @(x) sum(strcmp(x,{'histogram','pdf'}))==1);
            P.parse(ths,numstd,varargin{:});
            showmode = strcmp(P.Results.Mode,'histogram');
            ths = P.Results.ths;
            numstd = P.Results.numstd;
            figure;
            thresh_specified = ~isempty(ths);
            if thresh_specified
                control_groups = ...
                    intogroups(obj.segment_tbl(control_idx,:),ths);
                test_groups = ...
                    intogroups(obj.segment_tbl(~control_idx,:),ths);   
                len = numel(ths);
                ths = [0,ths];
            else
                control_groups =...
                    obj.segment_tbl.median_red(control_idx);
                test_groups = ...
                    obj.segment_tbl.median_red(~control_idx);
                len = 2;
            end
            for i = 1:len-1
                if thresh_specified
                    subplot(ceil(sqrt(len)),ceil(sqrt(len)),i);
                    cur_controls = control_groups{i};
                    cur_tests = test_groups{i};
                    title(sprintf('%d-%d um diameter',ths(i),ths(i+1)));
                else
                    cur_controls = control_groups;
                    cur_tests = test_groups;
                end
                if showmode
                    histogram(cur_controls,100,'FaceColor','#8c1515',...
                        'Normalization','probability');
                    hold on;
                    histogram(cur_tests,100,'FaceColor','#09425A',...
                        'Normalization','probability');
                else
                    [control_density, control_vals] =...
                        ksdensity(cur_controls);
                    [test_density, test_vals] =...
                        ksdensity(cur_tests);
                    a1 = area(control_vals,...
                        100*control_density./sum(control_density),...
                        'FaceColor','#8c1515');
                    a1.FaceAlpha = 0.5;
                    hold on;
                    a2 = area(test_vals,...
                        100*test_density./sum(test_density),...
                        'FaceColor','#09425A');
                    a2.FaceAlpha = 0.5;
                end
                xlabel('EB intensity [A.U.]');
                ylabel('# Vessels [%]');
                legend('control','MB + FUS');
                if isnumeric(numstd) && ~isempty(numstd)
                   xline(mean(cur_controls)+numstd*std(cur_controls),...
                       'LineWidth',2,'LineStyle','--');
                   legend('control','MB + FUS',...
                       ['Control mean + ',num2str(numstd),' SDs']);
                end
                xlim([0,1]);
                hold off; 
            end
        end
        function diamHist(obj)
            % histogram of blood vessel diameter. 
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            control_diams = obj.segment_tbl.median_segment_diam_um(control_idx);
            test_diams = obj.segment_tbl.median_segment_diam_um(~control_idx);
            histogram(control_diams,0.5:1:25.5,...
                'Normalization','probability','FaceColor','#007C92'); 
            hold on;
            histogram(test_diams,0.5:1:25.5,'Normalization','probability',...\
                'FaceColor','#E98300');
            legend(['Control-',num2str(numel(control_diams)),' total segments']...
                ,['Treatment-',num2str(numel(test_diams)),' total segments']);
            xlabel('Vessel diameter [um]'); ylabel('% of total vessels');
            xticks(1:25)
            title('Blood vessel diameter histogram'); 
            p = anova1(obj.segment_tbl.median_segment_diam_um,control_idx)
            xticklabels({'control','MB + FUS'});
            ylabel('Diameter [um]');
        end
        function perc_tbl = openedHist(obj,varargin)
            % plot the histogram of fraction of opened vesseles by diameter
            % Inputs:
            %   ths - array of diameters to be used as diameter ..
            %       groups.
            %   Intrabrain - logical flag:
            %       0 = plot all brains together,
            %       1 = plot each brain seperatly
            % Name-Value pair arguements:
            %   Errorbars - 'on' or 'off' (default), only shows errorbars
            %       if intrabrain is set to 1
            % Output:
            %   perc_tbl = opening percentage table by dimeter and frame
            
            P = inputParser();
            P.addOptional('ths',[2:10],@(x) isnumeric(x));
            P.addParameter('Intrabrain',0,@(x) sum(ismember(x,[0,1])) == 1);
            P.addParameter('Errorbars','off',...
                @(x) sum(strcmp(x,{'on','off'})) == 1);
            P.parse(varargin{:})
            
            ths = P.Results.ths;
            intrabrain = P.Results.Intrabrain;
            
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            test_frames = unique(obj.segment_tbl.image_name(~control_idx));
            ths = [0, ths];
            len_diam_groups = length(ths)-1;
            n_animals = numel(test_frames);
            perc = zeros(len_diam_groups,n_animals);
            vessel_count_per_brain = perc;
            for i = 1:len_diam_groups
                for j = 1:n_animals
                    in_group = ...
                        obj.segment_tbl.median_segment_diam_um >= ths(i) &...
                        obj.segment_tbl.median_segment_diam_um < ths(i+1) &...
                        strcmp(obj.segment_tbl.image_name,test_frames(j));
                    vessel_count_per_brain(i,j) = sum(in_group);
                    open_temp = in_group & obj.segment_tbl.opening;
                    perc(i,j) = 100*(sum(open_temp)/sum(in_group));
                end
            end
            switch intrabrain
                case 0
                    % Preform whole group analysis
                    bar(mean(perc,2,'omitnan'),0.5,'FaceColor','#009779');
                    if strcmp(P.Results.Errorbars,'on')
                        hold on;
                        errorbar(1:len_diam_groups,mean(perc,2,'omitnan'),...
                                    [],std(perc,0,2,'omitnan'),'k',...
                                    'LineStyle','none');
                    end
                case 1
                    subplot(2,2,2)
                    bar(100*perc./max(perc,[],1),0.5);
                    legend(test_frames)
                    xlabel('Blood vessel diameter [um]'); 
                    xticklabels(generate_xticks(ths(2:end)));
                    ylabel('Open vessel fraction / max Opened vessel fraction');
                    title({'Opened vessel fraction as function of diameter',...
                        'Normalized by maximal percentage'});
                    subplot(2,2,3)
                    bar(perc./sum(vessel_count_per_brain,1),0.5);
                    legend(test_frames)
                    xlabel('Blood vessel diameter [um]'); 
                    xticklabels(generate_xticks(ths(2:end)));
                    ylabel('Total number of opened vessels');
                    title({'Opened vessel fraction as function of diameter',...
                        'Normalized by total number of vessels in the brain'});
                    subplot(2,2,4)
                    bar(perc./vessel_count_per_brain,0.5);
                    legend(test_frames)
                    xlabel('Blood vessel diameter [um]'); 
                    xticklabels(generate_xticks(ths(2:end)));
                    ylabel('Total number of opened vessels');
                    title({'Opened vessel fraction as function of diameter',...
                        'Normalized by number of vessels in group'});
                    subplot(2,2,1)
                    bar(perc,0.5);
                    legend(test_frames)
            end
            xlabel('Blood vessel diameter [um]'); 
            xticklabels(generate_xticks(ths(2:end)));
            ylabel('Open vessel fraction [%]');
            title('Opened vessel fraction as function of diameter'); 
            
            perc_tbl = array2table(perc,'VariableNames',test_frames,...
                'RowNames',generate_xticks(ths(2:end)));
        end
        function regionHistogram(obj)
           % Return the region distribution of frames from each brain
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            frame_label = cellfun(@(x) textscan(x,'%s','Delimiter','_'),...
                obj.segment_tbl.image_name);
            animal_names = cellfun(@(x) x{1},frame_label,'UniformOutput',...
                false);
            region = cellfun(@(x) x{3},frame_label,'UniformOutput',...
                false);
            region = prettify_region(region);
            test_animals = unique(animal_names(~control_idx));
            regions = unique(region(~control_idx));
            counts = zeros(numel(regions),numel(test_animals));
            for i = 1:numel(regions)
                for j = 1:numel(test_animals)
                    counts(i,j) = sum(strcmp(region,regions(i)) &...
                        strcmp(animal_names,test_animals(j)));
                end
            end
            figure;
            bar(counts,0.5);
            legend(test_animals)
            xticklabels(regions);
            ylabel('Total number of vessels');
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
    vertcat(tbl.median_red{:,:}),'VariableNames',...
    {'image_name','median_segment_diam_um','median_red'}); 
end
function ticklabels = generate_xticks(ths)
% Generate a cell array of xticks based on ths. where each tick is a string
% of 'ths(i-1)-ths(i)' and for the 1st threshold it is '0-ths(1)'
tmp = cellfun(@(x) num2str(x),num2cell(ths),'UniformOutput',false);
tmp = [{'0'},tmp];
ticklabels = tmp(1:end-1);
for i = 2:numel(tmp)
    ticklabels(i-1) = ...
        cellstr([tmp{i-1},'-',tmp{i}]);
end
end
function region_cell = prettify_region(raw)
% Function to extract only the region string for each raw string
region_cell = raw;
contains_dot = cellfun(@(x) contains(x,'.'), raw);
for i = find(contains_dot)'
    region_cell{i} = region_cell{i}(1:end-4);
end
end
function str = sigstars(p)
% Function to calculate significance stars based on p val
if p<=10^-4
   str = '****';
elseif p <=10^-3
   str = '***';
elseif p <=10^-2
   str = '**';
elseif p <=0.05
   str = '*';
else
   str = 'ns';
end
end