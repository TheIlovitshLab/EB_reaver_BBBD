classdef EB_analysis
    % EB analaysis results of control and treatment brain sections
    properties
        segment_tbl
        n_px
        from_px
        UM_PX    
    end
    methods
        %% General tabular functions
        function obj = EB_analysis(varargin)
            % Construction of new EB_analysis object.
            % Input arguements:
            %   control_file = control "EB_analysis_entire_folder" file
            %   MB_file = MB "EB_analysis_entire_folder" file
            %   NB_file = NB "EB_analysis_entire_folder" file
            %   um_px = ratio of microns to pixel (default = 0.29288)
            P = inputParser();
            num_groups = input("How many groups to analyze? (2/3)\n");
            
            switch num_groups
                case 3
                    P.addOptional('control_file',[],@(x) isfile(x));
                    P.addOptional('MB_file',[],@(x) isfile(x));
                    P.addOptional('NB_file',[],@(x) isfile(x));
                    P.addOptional('um_px',0.29288,@(x) isnumeric(x));
                    P.parse(varargin{:});
                    control_file = P.Results.control_file;
                    MB_file = P.Results.MB_file;
                    NB_file = P.Results.NB_file;
                    obj.UM_PX = P.Results.um_px;
                    if isempty(control_file)
                        [file1,folder1] = uigetfile('*.mat','Choose control analysis file');
                        control_file = fullfile(folder1,file1);
                    end
                    control = load(control_file);
                    if isempty(MB_file)
                        [file2,folder2] = uigetfile('*.mat','Choose MBs treatment analysis file');
                        MB_file = fullfile(folder2,file2);
                    end
                    MB = load(MB_file);
                    if isempty(NB_file)
                        [file3,folder3] = uigetfile('*.mat','Choose NBs treatment analysis file');
                        NB_file = fullfile(folder3,file3);
                    end
                    NB = load(NB_file);
                    control_tbl = unpack_table(control.res.table);
                    label = cell(height(control_tbl),1);
                    label(:) = {'control'};
                    control_tbl.label = label;
                    MB_tbl = unpack_table(MB.res.table);
                    label = cell(height(MB_tbl),1);
                    label(:) = {'MB'};
                    MB_tbl.label = label;
                    NB_tbl = unpack_table(NB.res.table);
                    label = cell(height(NB_tbl),1);
                    label(:) = {'NB'};
                    NB_tbl.label = label;
                    obj.segment_tbl = vertcat(control_tbl,MB_tbl,NB_tbl);
                    obj.n_px = control.res.n_px;
                    obj.from_px = control.res.from_px;
                    obj = obj.classify_opening;

                case 2
                    treatment_group = input("What is the treatment group?\n" + ...
                        "for MB press 1\n" + ...
                        "for NB press 2\n");

                    switch treatment_group
                        case 1
                            P.addOptional('control_file',[],@(x) isfile(x));
                            P.addOptional('MB_file',[],@(x) isfile(x));
                            P.addOptional('um_px',0.29288,@(x) isnumeric(x));
                            P.parse(varargin{:});
                            control_file = P.Results.control_file;
                            MB_file = P.Results.MB_file;
                            obj.UM_PX = P.Results.um_px;
                            if isempty(control_file)
                                [file1,folder1] = uigetfile('*.mat','Choose control analysis file');
                                control_file = fullfile(folder1,file1);
                            end
                            control = load(control_file);
                            if isempty(MB_file)
                                [file2,folder2] = uigetfile('*.mat','Choose MBs treatment analysis file');
                                MB_file = fullfile(folder2,file2);
                            end
                            MB = load(MB_file);
                            control_tbl = unpack_table(control.res.table);
                            label = cell(height(control_tbl),1);
                            label(:) = {'control'};
                            control_tbl.label = label;
                            MB_tbl = unpack_table(MB.res.table);
                            label = cell(height(MB_tbl),1);
                            label(:) = {'MB'};
                            MB_tbl.label = label;
                            obj.segment_tbl = vertcat(control_tbl,MB_tbl);
                            obj.n_px = control.res.n_px;
                            obj.from_px = control.res.from_px;
                            obj = obj.classify_opening;

                        case 2
                            P.addOptional('control_file',[],@(x) isfile(x));
                            P.addOptional('NB_file',[],@(x) isfile(x));
                            P.addOptional('um_px',0.29288,@(x) isnumeric(x));
                            P.parse(varargin{:});
                            control_file = P.Results.control_file;
                            NB_file = P.Results.NB_file;
                            obj.UM_PX = P.Results.um_px;
                            if isempty(control_file)
                                [file1,folder1] = uigetfile('*.mat','Choose control analysis file');
                                control_file = fullfile(folder1,file1);
                            end
                            control = load(control_file);
                            if isempty(NB_file)
                                [file2,folder2] = uigetfile('*.mat','Choose NBs treatment analysis file');
                                NB_file = fullfile(folder2,file2);
                            end
                            NB = load(NB_file);
                            control_tbl = unpack_table(control.res.table);
                            label = cell(height(control_tbl),1);
                            label(:) = {'control'};
                            control_tbl.label = label;
                            NB_tbl = unpack_table(NB.res.table);
                            label = cell(height(NB_tbl),1);
                            label(:) = {'NB'};
                            NB_tbl.label = label;
                            obj.segment_tbl = vertcat(control_tbl,NB_tbl);
                            obj.n_px = control.res.n_px;
                            obj.from_px = control.res.from_px;
                            obj = obj.classify_opening;
                    end
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
        function writecsv(obj,ths,control_csv_filename,MB_csv_filename,NB_csv_filename,varargin)
            % save control and MB data to csv in a graphpad format
            % Inputs:
            %   ths = diameter grouop edges
            %   control_csv_filename = path to csv file for control group
            %   MB_csv_filename = path to csv file for MB group
            %   NB_csv_filename = path to csv file for NB group
            % Name-Value pair arguements:
            %   GroupByFrame = boolean flag (default = 0) 
            P = inputParser();
            P.addOptional('GroupByFrame',0,@(x) ismember(x,[0,1]));
            P.parse(varargin{:});
            GroupByFrame = P.Results.GroupByFrame;
            if nargin < 1
                ths = 2:10;
            end
            if nargin < 3
                [control_csv_filename, control_csv_folder] = ...
                    uiputfile({'*.csv';'*.xlsx'},'Specify control csv file name');
                control_csv_filename = ...
                    fullfile(control_csv_folder,control_csv_filename);
                [MB_csv_filename, MB_csv_folder] = ...
                    uiputfile({'*.csv';'*.xlsx'},'Specify MB csv file name');
                MB_csv_filename = ...
                    fullfile(MB_csv_folder, MB_csv_filename);
                [NB_csv_filename, NB_csv_folder] = ...
                    uiputfile({'*.csv';'*.xlsx'},'Specify NB csv file name');
                NB_csv_filename = ...
                    fullfile(NB_csv_folder, NB_csv_filename);
            end
            control_idx = cellfun(@(x) strcmp(x,'control'),obj.segment_tbl.label);
            n_bins = numel(ths);
            control_discrete_cell = intogroups(...
                obj.segment_tbl(control_idx,:),ths,GroupByFrame);
            MB_discrete_cell = intogroups(...
                obj.segment_tbl(~control_idx,:),ths,GroupByFrame);
            NB_discrete_cell = intogroups(...
                obj.segment_tbl(~control_idx,:),ths,GroupByFrame);
            str_cell = cell(n_bins-1,1);
            ths = [0,ths];
            for i = 1:n_bins
                str_cell{i} = sprintf('%d - %d',ths(i),ths(i+1));
            end
            control_tbl = cell2table(...
                [str_cell,control_discrete_cell],...
                'VariableNames',{'Diameter','red intensity'});
            MB_tbl = cell2table(...
                [str_cell,MB_discrete_cell],...
                'VariableNames',{'Diameter','red intensity'});
            NB_tbl = cell2table(...
                [str_cell,NB_discrete_cell],...
                'VariableNames',{'Diameter','red intensity'});
            writetable(control_tbl, control_csv_filename);
            writetable(MB_tbl, MB_csv_filename);
            writetable(NB_tbl, NB_csv_filename);
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
                numstd = 2;
            end
            if nargin < 2
               ths = 2:10;
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
                    new_obj.segment_tbl.median_red >= treat_th(i)) = 1;
            end
        end
        function new_obj = match_histograms(obj)
           % At each diameter group, remove the outliers from one of the 
           % conditions (Conrtol/MB/NB) to have equal number of vessel
           % segments in both conditions.
           control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
           MB_idx = cellfun(@(x) strcmp(x,'MB'),...
                obj.segment_tbl.label);
           NB_idx = cellfun(@(x) strcmp(x,'NB'),...
                obj.segment_tbl.label);
           ths = unique(ceil(obj.segment_tbl.median_segment_diam_um));
           ths = [0,ths'];
           new_obj = obj;
           rm_rows = [];
           for i = 1:length(ths)-1  % diameters
               cur_control = new_obj.segment_tbl.median_red(...
                   new_obj.segment_tbl.median_segment_diam_um >= ths(i) &...
                   new_obj.segment_tbl.median_segment_diam_um < ths(i+1) &...
                   control_idx);
               cur_MB = new_obj.segment_tbl.median_red(...
                   new_obj.segment_tbl.median_segment_diam_um >= ths(i) &...
                   new_obj.segment_tbl.median_segment_diam_um < ths(i+1) &...
                   MB_idx);
               cur_NB = new_obj.segment_tbl.median_red(...
                   new_obj.segment_tbl.median_segment_diam_um >= ths(i) &...
                   new_obj.segment_tbl.median_segment_diam_um < ths(i+1) &...
                   NB_idx);
               
               [~, I] = min([numel(cur_control), numel(cur_MB), numel(cur_NB)]);
               switch I
                
                   case 1   % smallest group size - control
                   n_outliers_1 = numel(cur_MB) - numel(cur_control);
                   [~,intensity_idx_1] = ...
                       sort(abs(cur_MB-mean(cur_MB)), 'descend');
                   MB_rows = find(MB_idx);
                   rm_rows = [rm_rows;...
                       MB_rows(intensity_idx_1(1:n_outliers_1))];

                   n_outliers_2 = numel(cur_NB) - numel(cur_control);
                   [~,intensity_idx_2] = ...
                       sort(abs(cur_NB-mean(cur_NB)), 'descend');
                   NB_rows = find(NB_idx);
                   rm_rows = [rm_rows;...
                       NB_rows(intensity_idx_2(1:n_outliers_2))];

                   case 2   % smallest group size - MBs
                   n_outliers_1 = numel(cur_control) - numel(cur_MB);
                   [~,intensity_idx_1] = ...
                       sort(abs(cur_control-mean(cur_control)), 'descend');
                   control_rows = find(control_idx);
                   rm_rows = [rm_rows;...
                       control_rows(intensity_idx_1(1:n_outliers_1))];

                   n_outliers_2 = numel(cur_NB) - numel(cur_MB);
                   [~,intensity_idx_2] = ...
                       sort(abs(cur_NB-mean(cur_NB)), 'descend');
                   NB_rows = find(NB_idx);
                   rm_rows = [rm_rows;...
                       NB_rows(intensity_idx_2(1:n_outliers_2))];

                   case 3   % smallest group size - NBs
                       n_outliers_1 = numel(cur_control) - numel(cur_NB);
                       [~,intensity_idx_1] = ...
                           sort(abs(cur_control-mean(cur_control)), 'descend');
                       control_rows = find(control_idx);
                       rm_rows = [rm_rows;...
                           control_rows(intensity_idx_1(1:n_outliers_1))];
    
                       n_outliers_2 = numel(cur_MB) - numel(cur_NB);
                       [~,intensity_idx_2] = ...
                           sort(abs(cur_MB-mean(cur_MB)), 'descend');
                       MB_rows = find(MB_idx);
                       rm_rows = [rm_rows;...
                           MB_rows(intensity_idx_2(1:n_outliers_2))];
               end
           end
           new_obj.segment_tbl(rm_rows,:) = [];
           new_obj = new_obj.classify_opening;
        end
        function new_obj = remove_penetrating(obj, T_diam, T_len)
            % Function to remove vessels that have both small diameter and
            % short length (directed at penetrating vessels)
            % Inputs:
            %   T_diam = diameter threshold [um]
            %   T_len = length threshold [um]
            new_obj = obj;
            new_obj.segment_tbl(...
                new_obj.segment_tbl.median_segment_diam_um<T_diam &...
                new_obj.segment_tbl.len<T_len,:) = [];
            new_obj = new_obj.classify_opening;
        end
        %% Plotting functions
        function scatterPlot(obj)
            % Simple scatter plot of all the vessel segments as 2D points 
            % in the diameter-extravasation plane
            exp_groups = unique(obj.segment_tbl.("label"));
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            MB_idx = cellfun(@(x) strcmp(x,'MB'),...
                obj.segment_tbl.label);
            NB_idx = cellfun(@(x) strcmp(x,'NB'),...
                obj.segment_tbl.label);
            scatter(...
                obj.segment_tbl.median_segment_diam_um(control_idx),...
                obj.segment_tbl.median_red(control_idx), 'MarkerEdgeColor', '#8c1515');
            hold on;
            scatter(...
                obj.segment_tbl.median_segment_diam_um(MB_idx),...
                obj.segment_tbl.median_red(MB_idx), 'MarkerEdgeColor', '#09425A');
            
            hold on;
            scatter(...
                obj.segment_tbl.median_segment_diam_um(NB_idx),...
                obj.segment_tbl.median_red(NB_idx), 'MarkerEdgeColor', '#77AC30');
            if length(exp_groups) == 3
                legend('control','MB + FUS', 'NB + FUS');
            else
                if ismember('MB', exp_groups)
                    legend('control','MB + FUS');
                elseif ismember('NB', exp_groups)
                    legend('control','NB + FUS');
                end
            end
            title(sprintf('[%d,%d] px',...
                obj.from_px,obj.from_px+obj.n_px));
            xlabel('median segment diameter [um]'); 
            ylabel('Median red pixel intensity [A.U.]');
            xlim([0 15])
        end
        function fitplot(obj,ths,fitType)
            % line plot with two lines representing the control and MB
            % samples in the diameter-extravasation plane, each line is
            % added with the error bars.
            % Inputs:
            %   ths (optional)- array of diameters to be used as x-axis.
            %       vessels with diameter larger than ths(end) will not be
            %       presented.
            %   fitType (optional)- fittype object to fit the data.
            %       specifing this will add the fitted equations to the plot.
            %       different fits can be specified to the control and MB
            %       via a cell array of 1 x 2. example {'poly1','poly2'}
            %       will fit th control data with a linear equation and the
            %       MB data with a quadratic equation.
            if nargin < 2
                ths = 2:10;
            end
            exp_groups = unique(obj.segment_tbl.("label"));
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            MB_idx = cellfun(@(x) strcmp(x,'MB'),...
                obj.segment_tbl.label);
            NB_idx = cellfun(@(x) strcmp(x,'NB'),...
                obj.segment_tbl.label);
            control_groups = ...
                intogroups(obj.segment_tbl(control_idx,:),ths);
            MB_groups = ...
                intogroups(obj.segment_tbl(MB_idx,:),ths);
            NB_groups = ...
                intogroups(obj.segment_tbl(NB_idx,:),ths);
            MB_red = cellfun(@(x) mean(x),MB_groups);
            NB_red = cellfun(@(x) mean(x),NB_groups);
            control_red = cellfun(@(x) mean(x),control_groups);
            MB_red_std = cellfun(@(x) std(x),MB_groups);
            NB_red_std = cellfun(@(x) std(x),NB_groups);
            control_red_std = cellfun(@(x) std(x),control_groups);
            errorbar(control_red,control_red_std,'Color','#8c1515');...
                hold on; errorbar(MB_red,MB_red_std,'Color','#09425A');...
                hold on; errorbar(NB_red,NB_red_std,'Color','#77AC30')
            if nargin > 2
                if isa(fitType,'char')  % if user specified a single fitType object for both groups
                    tmp = fitType;
                    fitType = cell(1,2); fitType(:) = cellstr(tmp);
                end
                control_median_diams = ...
                    obj.segment_tbl.median_segment_diam_um(control_idx);
                control_eb = ...
                    obj.segment_tbl.median_red(control_idx);
                MB_median_diams = ...
                    obj.segment_tbl.median_segment_diam_um(MB_idx);
                MB_eb = ...
                    obj.segment_tbl.median_red(MB_idx);
                NB_median_diams = ...
                    obj.segment_tbl.median_segment_diam_um(NB_idx);
                NB_eb = ...
                    obj.segment_tbl.median_red(NB_idx);
                [f1,gof1] = ...
                    fit(control_median_diams(control_median_diams >= ths(1) &...
                    control_median_diams <= ths(end)),...
                    control_eb(control_median_diams >= ths(1) &...
                    control_median_diams <= ths(end))...
                    ,fitType{1});
                [f2,gof2] = ...
                    fit(MB_median_diams(MB_median_diams >= ths(1) &...
                    MB_median_diams <= ths(end)),...
                    MB_eb(MB_median_diams >= ths(1) &...
                    MB_median_diams <= ths(end))...
                    ,fitType{2});
                [f3,gof3] = ...
                    fit(NB_median_diams(NB_median_diams >= ths(1) &...
                    NB_median_diams <= ths(end)),...
                    NB_eb(NB_median_diams >= ths(1) &...
                    NB_median_diams <= ths(end))...
                    ,fitType{3});
                plot(f1)
                plot(f2)
                plot(f3)
                h= get(gca, 'Children');
                set(h(2),'Color','#8c1515', 'LineStyle','--');
                set(h(1),'Color','#09425A', 'LineStyle','--');
                set(h(3),'Color','#77AC30', 'LineStyle','--');

                if length(exp_groups) == 3
                    legend('control','MB', 'NB',...
                    strrep(fitstr(f1,gof1),'y','y(control)'),...
                    strrep(fitstr(f2,gof2),'y','y(MB+FUS)'),...
                    strrep(fitstr(f3,gof3),'y','y(NB+FUS)'));
                else
                    if ismember('MB', exp_groups)
                        legend('control','MB', 'NB',...
                        strrep(fitstr(f1,gof1),'y','y(control)'),...
                        strrep(fitstr(f2,gof2),'y','y(MB+FUS)'));
                    elseif ismember('NB', exp_groups)
                    legend('control','MB', 'NB',...
                    strrep(fitstr(f1,gof1),'y','y(control)'),...
                    strrep(fitstr(f3,gof3),'y','y(NB+FUS)'));
                    end
                end
            else
                if length(exp_groups) == 3
                    legend('control','MB + FUS', 'NB + FUS');
                else
                    if ismember('MB', exp_groups)
                        legend('control','MB + FUS', '');
                    elseif ismember('NB', exp_groups)
                        legend('control','', 'NB + FUS');
                    end
                end
            end
            xlabel('median segment diameter [\mum]'); 
            ylabel('Median red pixel intensity [A.U.]');
        end
        function violinplot(obj,ths,groups, varargin)
            % Implementation of violin plot
            % Inputs:
            %   ths (optional)- array of diameters to be used as x-axis.
            %       vessels with diameter larger than ths(end) will not be
            %       presented. if ths not specified a single violin will be
            %       plotted for all vessel diameters
            %   groups - switch with 3 options for plotting, if not specified:
            %       0 = control + MB
            %       1 = control + NB
            %       2 = MB + NB
            %   varargin - input arguements of the varargin function by
            %       B. Bechtold
            %       (https://github.com/bastibe/Violinplot-Matlab)
            exp_groups = unique(obj.segment_tbl.("label"));
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            MB_idx = cellfun(@(x) strcmp(x,'MB'),...
                obj.segment_tbl.label);
            NB_idx = cellfun(@(x) strcmp(x,'NB'),...
                obj.segment_tbl.label);
            figure;
            if nargin < 2  % No diameter thresholds specified
                if length(exp_groups) == 2 && ismember('NB', exp_groups)
                    control_groups = ...
                        obj.segment_tbl.median_red(control_idx);
                    NB_groups = ...
                        obj.segment_tbl.median_red(NB_idx);
                    control_groups = rmoutliers(control_groups);
                    NB_groups = rmoutliers(NB_groups);
                    Violin({control_groups},1,...
                        'HalfViolin','left','ViolinColor',{[1,0,0]},...
                        varargin{:});
                    hold on;
                    Violin({NB_groups},1,...
                        'HalfViolin','right','ViolinColor',{[0,1,0]},...
                        varargin{:});
                    xticks([]);
                    hold off;
                else
                    control_groups = ...
                        obj.segment_tbl.median_red(control_idx);
                    MB_groups = ...
                        obj.segment_tbl.median_red(MB_idx);
                    control_groups = rmoutliers(control_groups);
                    MB_groups = rmoutliers(MB_groups);
                    Violin({control_groups},1,...
                        'HalfViolin','left','ViolinColor',{[1,0,0]},...
                        varargin{:});
                    hold on;
                    Violin({MB_groups},1,...
                        'HalfViolin','right','ViolinColor',{[0,0,1]},...
                        varargin{:});
                    xticks([]);
                    hold off;
                end
            else
                if nargin < 3
                    if length(exp_groups) == 3
                        groups = 2;
                    else
                        if ismember('MB', exp_groups)
                            groups = 0;
                        elseif ismember('NB', exp_groups)
                            groups = 1;
                        end
                    end
                end
                switch groups
                    case 0
                        control_groups = ...
                            intogroups(obj.segment_tbl(control_idx,:),ths);
                        MB_groups = ...
                            intogroups(obj.segment_tbl(MB_idx,:),ths);
                        % remove outliers
                        control_groups = cellfun(@(x) rmoutliers(x),...
                            control_groups,'UniformOutput',false);
                        MB_groups = cellfun(@(x) rmoutliers(x),...
                            MB_groups,'UniformOutput',false);
                        for i = 1:numel(control_groups)
                            if ~isempty(control_groups{i})
                                Violin(control_groups(i),i,...
                                    'HalfViolin','left','ViolinColor',{[1,0,0]});
                                hold on;
                            end
                        end
                        for i = 1:numel(MB_groups)
                            if ~isempty(MB_groups{i})
                                Violin(MB_groups(i),i,...
                                    'HalfViolin','right','ViolinColor',{[0,0,1]});
                                hold on;
                            end
                        end
                        xticks([1:numel(control_groups)]);
                        xticklabels(generate_xticks(ths));
                        xlabel('Diameter [um]');
                        hold off;
                    
                        ylabel('Median red intensity in perivscular area [A.U.]');
                        ax = gca;
                        ch = get(ax,'Children');
                        red_envalope = ch(end-1);
                        blue_envalope = ch(7);
                        legend([red_envalope,blue_envalope],{'control','MB + FUS'})
                        box;

                case 1  % control - NB
                    control_groups = ...
                        intogroups(obj.segment_tbl(control_idx,:),ths);
                    NB_groups = ...
                        intogroups(obj.segment_tbl(NB_idx,:),ths);
                    % remove outliers
                    control_groups = cellfun(@(x) rmoutliers(x),...
                        control_groups,'UniformOutput',false);
                    NB_groups = cellfun(@(x) rmoutliers(x),...
                        NB_groups,'UniformOutput',false);
                    for i = 1:numel(control_groups)
                        if ~isempty(control_groups{i})
                            Violin(control_groups(i),i,...
                                'HalfViolin','left','ViolinColor',{[1,0,0]});
                            hold on;
                        end
                    end
                    for i = 1:numel(NB_groups)
                        if ~isempty(NB_groups{i})
                            Violin(NB_groups(i),i,...
                                'HalfViolin','right','ViolinColor',{[0,1,0]});
                            hold on;
                        end
                    end
                    xticks([1:numel(control_groups)]);
                    xticklabels(generate_xticks(ths));
                    xlabel('Diameter [um]');
                    hold off;
                    ylabel('Median red intensity in perivscular area [A.U.]');
                    ax = gca;
                    ch = get(ax,'Children');
                    red_envalope = ch(end-1);
                    blue_envalope = ch(7);
                    legend([red_envalope,blue_envalope],{'control','NB + FUS'})
                    box;

               case 2  % MB - NB
                    MB_groups = ...
                        intogroups(obj.segment_tbl(MB_idx,:),ths);
                    NB_groups = ...
                        intogroups(obj.segment_tbl(NB_idx,:),ths);
                    % remove outliers
                    MB_groups = cellfun(@(x) rmoutliers(x),...
                        MB_groups,'UniformOutput',false);
                    NB_groups = cellfun(@(x) rmoutliers(x),...
                        NB_groups,'UniformOutput',false);
                    for i = 1:numel(MB_groups)
                        if ~isempty(MB_groups{i})
                            Violin(MB_groups(i),i,...
                                'HalfViolin','left','ViolinColor',{[0,0,1]});
                            hold on;
                        end
                    end
                    for i = 1:numel(NB_groups)
                        if ~isempty(NB_groups{i})
                            Violin(NB_groups(i),i,...
                                'HalfViolin','right','ViolinColor',{[0,1,0]});
                            hold on;
                        end
                    end
                    xticks([1:numel(MB_groups)]);
                    xticklabels(generate_xticks(ths));
                    xlabel('Diameter [\mum]');
                    hold off;
                    ylabel('Median red intensity in perivscular area [A.U.]');
                    ax = gca;
                    ch = get(ax,'Children');
                    red_envalope = ch(end-1);
                    blue_envalope = ch(7);
                    legend([red_envalope,blue_envalope],{'MB + FUS','NB + FUS'})
                    box;
                end
            end
        end
        function barplot(obj,ths,groups)
            % Bar plot with significance stars.
            % Inputs:
            %   ths (optional)- array of diameters to be used as x-axis.
            %       vessels with diameter larger than ths(end) will not be
            %       presented.
            %   groups - switch with 3 options for plotting:
            %       0 = plot the subtraction between MB and control for
            %           each diameter
            %       1 = plot only the MB group and calculate statistical
            %           significance bewteen each diameter and the smallest
            %           diameter
            %       2 = plot control and MB and calculate statistical
            %           significance of difference between groups at each
            %           diameter seperatly
            %       3 = plot the subtraction between NB and control for
            %           each diameter
            %       4 = plot the subtraction between MB and control 
            %           and subtraction between NB and control for
            %           each diameter
            %       5 = plot only the NB group and calculate statistical
            %           significance bewteen each diameter and the smallest
            %           diameter
            %       6 = plot control and NB and calculate statistical
            %           significance of difference between groups at each
            %           diameter seperatly
            %       7 = plot control, MB and NB calculate statistical
            %           significance of difference between groups at each
            %           diameter seperatly
            %       -1 = plot only the control group and calculate statistical
            %           significance bewteen each diameter and the smallest
            %           diameter
            exp_groups = unique(obj.segment_tbl.("label"));
            ymax = 0;
            if nargin < 3
                if length(exp_groups) == 3
                        groups = 7;
                    else
                        if ismember('MB', exp_groups)
                            groups = 2;
                        elseif ismember('NB', exp_groups)
                            groups = 6;
                        end
                end
            end
            
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            MB_idx = cellfun(@(x) strcmp(x,'MB'),...
                obj.segment_tbl.label);
            NB_idx = cellfun(@(x) strcmp(x,'NB'),...
                obj.segment_tbl.label);
            if nargin < 2   % No diameter thresholds specified
                control_groups = ...
                    obj.segment_tbl.median_red(control_idx);
                MB_groups = ...
                    obj.segment_tbl.median_red(MB_idx);
                NB_groups = ...
                    obj.segment_tbl.median_red(NB_idx);
                control_mu_median = [mean(control_groups);
                    std(control_groups)];
                MB_mu_median = [mean(MB_groups);
                    std(MB_groups)];
                NB_mu_median = [mean(NB_groups);
                    std(NB_groups)];
                control_groups = rmoutliers(control_groups);
                MB_groups = rmoutliers(MB_groups);
                NB_groups = rmoutliers(NB_groups);
                ths = 0;
            else
                control_groups = ...
                    intogroups(obj.segment_tbl(control_idx,:),ths);
                MB_groups = ...
                    intogroups(obj.segment_tbl(MB_idx,:),ths);
                NB_groups = ...
                    intogroups(obj.segment_tbl(NB_idx,:),ths);
                control_mu_median = cellfun(@(x) [mean(x);std(x)],...
                    control_groups,'UniformOutput',false);
                control_mu_median = [control_mu_median{:}];
                MB_mu_median = cellfun(@(x) [mean(x);std(x)],...
                    MB_groups,'UniformOutput',false);
                MB_mu_median = [MB_mu_median{:}];
                NB_mu_median = cellfun(@(x) [mean(x);std(x)],...
                    NB_groups,'UniformOutput',false);
                NB_mu_median = [NB_mu_median{:}];
                % remove outliers
                control_groups = cellfun(@(x) rmoutliers(x),...
                    control_groups,'UniformOutput',false);
                MB_groups = cellfun(@(x) rmoutliers(x),...
                    MB_groups,'UniformOutput',false);
                NB_groups = cellfun(@(x) rmoutliers(x),...
                    NB_groups,'UniformOutput',false);
            end
            switch groups
                case 1  % only MB
                    bar(1:2:(length(ths)*2),MB_mu_median(1,:),0.5,...
                        'FaceColor','#09425A');
                    hold on;
                    errorbar(1:2:(length(ths)*2),MB_mu_median(1,:),...
                        MB_mu_median(2,:),MB_mu_median(2,:),...
                        'LineStyle','none'); 
                    xticks(1:2:(length(ths)*2));
                    xticklabels(generate_xticks(ths));
                    title(sprintf('MBs - [%d,%d] px',...
                        obj.from_px,obj.from_px+obj.n_px));
                    xlabel('Vessel diameter [um]');
                    ylabel('Median red intensity in perivascular area [A.U.]')

                    for i = 2:numel(ths)
                       [~,p_MB] = ttest2(MB_groups{i-1},MB_groups{i});
                       st = sigstars(p_MB);
                       if ~strcmp(st,'ns')
                           maxy = max(sum(MB_mu_median(1:2,:),1))*(1+i/20);
                           line([(i-1)*2,(i+1)*2],maxy*[1,1]);
                           pos = (i-1)*2+1.5-length(st)*0.25;
                           y_pos = maxy*1.01;
                           text(pos,y_pos,st);
                       end
                    end

                case 5  % only NB
                    bar(1:2:(length(ths)*2),NB_mu_median(1,:),0.5,...
                        'FaceColor','#77AC30');
                    hold on;
                    errorbar(1:2:(length(ths)*2),NB_mu_median(1,:),...
                        NB_mu_median(2,:),NB_mu_median(2,:),...
                        'LineStyle','none'); 
                    xticks(1:2:(length(ths)*2));
                    xticklabels(generate_xticks(ths));
                    title(sprintf('NB - [%d,%d] px',...
                        obj.from_px,obj.from_px+obj.n_px));
                    xlabel('Vessel diameter [um]');
                    ylabel('Median red intensity in perivascular area [A.U.]')

                    for i = 2:numel(ths)
                       [~,p_MB] = ttest2(MB_groups{i-1},MB_groups{i});
                       st = sigstars(p_MB);
                       if ~strcmp(st,'ns')
                           maxy = max(sum(NB_mu_median(1:2,:),1))*(1+i/20);
                           line([(i-1)*2,(i+1)*2],maxy*[1,1]);
                           pos = (i-1)*2+1.5-length(st)*0.25;
                           y_pos = maxy*1.01;
                           text(pos,y_pos,st);
                       end
                    end

                case 2  % MB + control
                    if length(ths) == 1
                        b1 = bar(0.75,control_mu_median(1,:),0.25,...
                            'FaceColor','#8c1515');
                        hold on;
                        b2 =bar(1.25,MB_mu_median(1,:),0.25,...
                            'FaceColor','#09425A');
                        errorbar(0.75,control_mu_median(1,:),...
                            control_mu_median(2,:),control_mu_median(2,:),...
                            'k', 'LineStyle','none');
                        errorbar(1.25,MB_mu_median(1,:),...
                            MB_mu_median(2,:),MB_mu_median(2,:),'k',...
                            'LineStyle','none'); 
                        xticks([]);
                        % Add significance stars of control vs MB of same diameter
                       [~,p_MB] = ttest2(control_groups,MB_groups);
                       maxy = max([sum(control_mu_median),...
                           sum(MB_mu_median)]);
                       line([0.5,1.5],(maxy*1.05)*[1,1]);
                       text(0.5,maxy*1.08,sigstars(p_MB));
                    else
                        b1 = bar(0.75:2:(length(ths)*2),...
                            control_mu_median(1,:),0.25,...
                            'FaceColor','#8c1515');
                        hold on;
                        b2 =bar(1.25:2:(length(ths)*2),...
                            MB_mu_median(1,:),0.25,...
                            'FaceColor','#09425A');
                        errorbar(0.75:2:(length(ths)*2),control_mu_median(1,:),...
                            control_mu_median(2,:),control_mu_median(2,:),'k',...
                            'LineStyle','none');
                        errorbar(1.25:2:(length(ths)*2),MB_mu_median(1,:),...
                            MB_mu_median(2,:),MB_mu_median(2,:),'k',...
                            'LineStyle','none'); 
                        xticks(1:2:(length(ths)*2));
                        xticklabels(generate_xticks(ths));
                        xlabel('Vessel diameter [um]');
                        % Add significance stars of control vs MB of same diameter
                        for i = 1:length(ths)
                           [~,p_MB] = ttest2(control_groups{i},MB_groups{i});
                           maxy = max([sum(control_mu_median(:,i)),sum(MB_mu_median(:,i))]);
                           x_cord = i-1;
                           line([0.5,1.5]+x_cord*2,(maxy*1.05)*[1,1]);
                           text(x_cord*2+0.5,maxy*1.08,sigstars(p_MB));
                        end
                    end
                    ylim([0,maxy*1.3]);
                    legend([b1,b2],'control','MB + FUS');
                    title('Median Red Intensity as Function of Vessel Diameter');
                    ylabel('Median red intensity in perivascular area [A.U.]')


                case 6  % NB + control
                    if length(ths) == 1
                        b1 = bar(0.75,control_mu_median(1,:),0.25,...
                            'FaceColor','#8c1515');
                        hold on;
                        b2 =bar(1.25,NB_mu_median(1,:),0.25,...
                            'FaceColor','#77AC30');
                        errorbar(0.75,control_mu_median(1,:),...
                            control_mu_median(2,:),control_mu_median(2,:),...
                            'k', 'LineStyle','none');
                        errorbar(1.25,NB_mu_median(1,:),...
                            NB_mu_median(2,:),NB_mu_median(2,:),'k',...
                            'LineStyle','none'); 
                        xticks([]);
                        % Add significance stars of control vs NB of same diameter
                       [~,p_NB] = ttest2(control_groups,NB_groups);
                       maxy = max([sum(control_mu_median),...
                           sum(NB_mu_median)]);
                       line([0.5,1.5],(maxy*1.05)*[1,1]);
                       text(0.5,maxy*1.08,sigstars(p_NB));
                    else
                        b1 = bar(0.75:2:(length(ths)*2),...
                            control_mu_median(1,:),0.25,...
                            'FaceColor','#8c1515');
                        hold on;
                        b2 =bar(1.25:2:(length(ths)*2),...
                            NB_mu_median(1,:),0.25,...
                            'FaceColor','#77AC30');
                        errorbar(0.75:2:(length(ths)*2),control_mu_median(1,:),...
                            control_mu_median(2,:),control_mu_median(2,:),'k',...
                            'LineStyle','none');
                        errorbar(1.25:2:(length(ths)*2),NB_mu_median(1,:),...
                            NB_mu_median(2,:),NB_mu_median(2,:),'k',...
                            'LineStyle','none'); 
                        xticks(1:2:(length(ths)*2));
                        xticklabels(generate_xticks(ths));
                        xlabel('Vessel diameter [um]');
                        % Add significance stars of control vs NB of same diameter
                        for i = 1:length(ths)
                           [~,p_NB] = ttest2(control_groups{i},NB_groups{i});
                           maxy = max([sum(control_mu_median(:,i)),sum(NB_mu_median(:,i))]);
                           x_cord = i-1;
                           line([0.5,1.5]+x_cord*2,(maxy*1.05)*[1,1]);
                           text(x_cord*2+0.5,maxy*1.08,sigstars(p_NB));
                        end
                    end
                    ylim([0,maxy*1.3]);
                    legend([b1,b2],'control','NB + FUS');
                    title('Median Red Intensity as Function of Vessel Diameter');
                    ylabel('Median red intensity in perivascular area [A.U.]')

                case 7  % all 3 groups (MB + NB + control)
                    if length(ths) == 1
                        b1 = bar(0.75,control_mu_median(1,:),0.25,...
                            'FaceColor','#8c1515');
                        hold on;
                        b2 = bar(1.25,MB_mu_median(1,:),0.25,...
                            'FaceColor','#09425A');
                        hold on;
                        b3 =bar(1.75,NB_mu_median(1,:),0.25,...
                            'FaceColor','#77AC30');
                        errorbar(0.75,control_mu_median(1,:),...
                            control_mu_median(2,:),control_mu_median(2,:),...
                            'k', 'LineStyle','none');
                        errorbar(1.25,MB_mu_median(1,:),...
                            MB_mu_median(2,:),MB_mu_median(2,:),'k',...
                            'LineStyle','none');
                        errorbar(1.75,NB_mu_median(1,:),...
                            NB_mu_median(2,:),NB_mu_median(2,:),'k',...
                            'LineStyle','none');
                        xticks([]);
                        ylim = 0;
                    else
                        b1 = bar(0.75:2:(length(ths)*2),...
                            control_mu_median(1,:),0.25,...
                            'FaceColor','#8c1515');
                        hold on;
                        b2 =bar(1.25:2:(length(ths)*2),...
                            MB_mu_median(1,:),0.25,...
                            'FaceColor','#09425A');
                        hold on;
                        b3 =bar(1.75:2:(length(ths)*2),...
                            NB_mu_median(1,:),0.25,...
                            'FaceColor','#77AC30');
                        errorbar(0.75:2:(length(ths)*2),control_mu_median(1,:),...
                            control_mu_median(2,:),control_mu_median(2,:),'k',...
                            'LineStyle','none');
                        errorbar(1.25:2:(length(ths)*2),MB_mu_median(1,:),...
                            MB_mu_median(2,:),MB_mu_median(2,:),'k',...
                            'LineStyle','none');
                        errorbar(1.75:2:(length(ths)*2),NB_mu_median(1,:),...
                            NB_mu_median(2,:),NB_mu_median(2,:),'k',...
                            'LineStyle','none');
                        xticks(1:2:(length(ths)*2));
                        xticklabels(generate_xticks(ths));
                        xlabel('Vessel diameter [\mum]');

                        anova_results = cell2table(cell(0,4),'VariableNames', {'Vessels_Diameter', 'Control_MBs', 'Control_NBs', 'MBs_NBs'});
                        
                        ymax = 0;

                        % Add significance stars of control vs MB vs NB of same diameter
                        data = [];
                        bubble_type = [];
                        diameter = [];
                        diams = [];
                        for i = 1:numel(ths)
                            % save results to table
                            if i == 1
                                diam = strcat("0", " to ", string(ths(i)));
                            else
                                diam = strcat(string(ths(i-1)), " to ", string(ths(i)));
                            end
                            diams = [diams diam];

                            data = [data.' ; control_groups{i} ; MB_groups{i} ; NB_groups{i}].';
                            group_control = repmat(["control"], 1, length(control_groups{i}));
                            group_MB = repmat(["MBs"], 1, length(MB_groups{i}));
                            group_NB = repmat(["NBs"], 1, length(NB_groups{i}));
                            bubble_type = [bubble_type, group_control, group_MB, group_NB];
                            group_diameter = repmat([diam], 1, length(control_groups{i})+length(MB_groups{i})+length(NB_groups{i}));
                            diameter = [diameter, group_diameter];
                        end

                        % Perform ANOVA
                        [p, ~, stats] = anovan(data,{bubble_type diameter},'model',2,'varnames',{'bubble type','diameter'});
                        % Perform post-hoc tests (Tukey's honestly significant difference)
                        [c, ~, ~, gnames] = multcompare(stats, 'CType', 'hsd', 'Display','off', 'Dimension', [1, 2]);
    
                        tbl = array2table(c,"VariableNames", ...
                        ["Group A","Group B","Lower Limit","A-B","Upper Limit","P-value"]);
                        tbl.("Group A")=gnames(tbl.("Group A"));
                        tbl.("Group B")=gnames(tbl.("Group B"));
                        
                        idx_keep = [];
                        p_control_MB = [];
                        p_control_NB = [];
                        p_MB_NB = [];
                        for row=1:height(tbl)
                            if strcmp(tbl.("Group A"){row}(end-5:end), tbl.("Group B"){row}(end-5:end))
                                idx_keep = [idx_keep, row];
                                if strcmp(tbl.("Group A"){row}(13), 'c') && strcmp(tbl.("Group B"){row}(13), 'M')
                                    p_control_MB = [p_control_MB, tbl.("P-value")(row)];
                                elseif strcmp(tbl.("Group A"){row}(13), 'c') && strcmp(tbl.("Group B"){row}(13), 'N')
                                    p_control_NB = [p_control_NB, tbl.("P-value")(row)];
                                elseif strcmp(tbl.("Group A"){row}(13), 'M') && strcmp(tbl.("Group B"){row}(13), 'N')
                                    p_MB_NB = [p_MB_NB tbl.("P-value")(row)];
                                end
                            end
                        end
                        tbl =  tbl(idx_keep, :);
                        anova_results = array2table([diams.', p_control_MB.', p_control_NB.', p_MB_NB.'],"VariableNames", ...
                            ["Vessels_Diameter","Control_MBs","Control_NBs","MBs_NBs"]);
                        
                        for i = 1:numel(ths)
                            st_MB = sigstars(p_control_MB(i));
                            st_NB = sigstars(p_control_NB(i));
    
                            if ~strcmp(st_MB,'ns')
                                MB_poses = 1.25:2:(length(ths)*2);
                                pos = MB_poses(i);
                                MB_y_pos = sum(MB_mu_median(1:2,i)) + 0.03;
                                ymax = max([ymax, MB_y_pos + 0.05]);
                                text(pos,MB_y_pos,st_MB, 'Color', '#09425A', 'HorizontalAlignment', 'center', 'FontSize', 12);
                            end
    
                            if ~strcmp(st_NB,'ns')
                                NB_poses = 1.75:2:(length(ths)*2);
                                pos = NB_poses(i);
                                NB_y_pos = sum(NB_mu_median(1:2,i)) + 0.03;
                                ymax = max([ymax, NB_y_pos + 0.05]);
                                text(pos,NB_y_pos,st_NB, 'Color', '#77AC30', 'HorizontalAlignment', 'center', 'FontSize', 12);
                            end
                        end
                    end
%                     % Perform ANOVA
%                     [p, ~, stats] = anovan(data,{bubble_type diameter},'model',2,'varnames',{'bubble type','diameter'});
%                     % Perform post-hoc tests (Tukey's honestly significant difference)
%                     [c, ~, ~, gnames] = multcompare(stats, 'CType', 'hsd', 'Display','off', 'Dimension', [1, 2]);
% 
%                     tbl = array2table(c,"VariableNames", ...
%                     ["Group A","Group B","Lower Limit","A-B","Upper Limit","P-value"]);
%                     tbl.("Group A")=gnames(tbl.("Group A"));
%                     tbl.("Group B")=gnames(tbl.("Group B"));
%                     
%                     idx_keep = [];
%                     p_control_MB = [];
%                     p_control_NB = [];
%                     p_MB_NB = [];
%                     for row=1:height(tbl)
%                         if strcmp(tbl.("Group A"){row}(end-5:end), tbl.("Group B"){row}(end-5:end))
%                             idx_keep = [idx_keep, row];
%                             if strcmp(tbl.("Group A"){row}(13), 'c') && strcmp(tbl.("Group B"){row}(13), 'M')
%                                 p_control_MB = [p_control_MB, tbl.("P-value")(row)];
%                             elseif strcmp(tbl.("Group A"){row}(13), 'c') && strcmp(tbl.("Group B"){row}(13), 'N')
%                                 p_control_NB = [p_control_NB, tbl.("P-value")(row)];
%                             elseif strcmp(tbl.("Group A"){row}(13), 'M') && strcmp(tbl.("Group B"){row}(13), 'N')
%                                 p_MB_NB = [p_MB_NB tbl.("P-value")(row)];
%                             end
%                         end
%                     end
%                     tbl =  tbl(idx_keep, :);
%                     anova_results = array2table([diams.', p_control_MB.', p_control_NB.', p_MB_NB.'],"VariableNames", ...
%                         ["Vessels_Diameter","Control_MBs","Control_NBs","MBs_NBs"]);
%                     
%                     for i = 1:numel(ths)
%                         st_MB = sigstars(p_control_MB(i));
%                         st_NB = sigstars(p_control_NB(i));
% 
%                         if ~strcmp(st_MB,'ns')
%                             MB_poses = 1.25:2:(length(ths)*2);
%                             pos = MB_poses(i);
%                             MB_y_pos = sum(MB_mu_median(1:2,i)) + 0.03;
%                             ymax = max([ymax, MB_y_pos + 0.05]);
%                             text(pos,MB_y_pos,st_MB, 'Color', '#09425A', 'HorizontalAlignment', 'center', 'FontSize', 12);
%                         end
% 
%                         if ~strcmp(st_NB,'ns')
%                             NB_poses = 1.75:2:(length(ths)*2);
%                             pos = NB_poses(i);
%                             NB_y_pos = sum(NB_mu_median(1:2,i)) + 0.03;
%                             ymax = max([ymax, NB_y_pos + 0.05]);
%                             text(pos,NB_y_pos,st_NB, 'Color', '#77AC30', 'HorizontalAlignment', 'center', 'FontSize', 12);
%                         end
%                     end

                    legend([b1,b2, b3],'control','MB + FUS', 'NB + FUS');
                    title('Median Red Intensity as Function of Vessel Diameter');
                    ylabel('Median red intensity in perivascular area [A.U.]');
                    
                
                case 0  % diffrence MB-control
                    bar(0.75:2:((length(ths)-1)*2+0.75),...
                    MB_mu_median(1,:)-control_mu_median(1,:),0.25,...
                    'FaceColor','#09425A');
                    xticks(1:2:(length(ths)*2+1));
                    xticklabels(generate_xticks(ths));
                    title({'MBs treatment-control',...
                        [num2str(obj.n_px*obj.UM_PX),' um perivascular area']});
                    xlabel('Vessel diameter [um]');
                    ylabel('MB-control difference in Median red intensity [A.U.]')

                case 3  % diffrence NB-control
                    bar(0.75:2:((length(ths)-1)*2+0.75),...
                    NB_mu_median(1,:)-control_mu_median(1,:),0.25,...
                    'FaceColor','#77AC30');
                    xticks(1:2:(length(ths)*2+1));
                    xticklabels(generate_xticks(ths));
                    title({'NBs treatment-control',...
                        [num2str(obj.n_px*obj.UM_PX),' um perivascular area']});
                    xlabel('Vessel diameter [um]');
                    ylabel('NB-control difference in Median red intensity [A.U.]')

                case 4  % diffrence MB-control and NB-control
                    b1 = bar(0.75:2:((length(ths)-1)*2+0.75),...
                        MB_mu_median(1,:)-control_mu_median(1,:),0.25,...
                        'FaceColor','#09425A');
                    hold on;
                    b2 = bar(1.25:2:(length(ths)*2+0.75),...
                        NB_mu_median(1,:)-control_mu_median(1,:),0.25,...
                        'FaceColor','#77AC30');
                    xticks(1:2:(length(ths)*2+1));
                    xticklabels(generate_xticks(ths));
                    title({'MBs/NBs treatment-control',...
                        [num2str(obj.n_px*obj.UM_PX),' um perivascular area']});
                    xlabel('Vessel diameter [um]');
                    ylabel('Treatment-control difference in Median red intensity [A.U.]')
                    legend([b1,b2],'MB-control','NB-control');

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
                       [~,p_MB] = ttest2(control_groups{i-1},control_groups{i});
                       st = sigstars(p_MB);
                       if ~strcmp(st,'ns')
                           maxy = max(sum(MB_mu_median(1:2,:),1))*(1+i/20);
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
            % and MB groups groupd by their diameter.
            % Inputs:
            %   ths (optional)- array of diameters to be used as diameter ..
            %       groups.
            %   numstd (optional) - plot the threshold between control and
            %       MB as mean + numstd*sigma
            % Name-Value pair arguements:
            %   'Mode' (optional) - display mode, can either be 'histogram'
            %       (default) or 'pdf' which displys the kernel density
            exp_groups = unique(obj.segment_tbl.("label"));
            P = inputParser();
            P.addParameter('Mode','histogram',...
                @(x) sum(strcmp(x,{'histogram','pdf'}))==1);
            P.parse(varargin{:});
            showmode = strcmp(P.Results.Mode,'pdf');
            if nargin < 1
                ths = 2:10;
            end
            if nargin < 2
                numstd = 2;
            end
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            MB_idx = cellfun(@(x) strcmp(x,'MB'),...
                obj.segment_tbl.label);
            NB_idx = cellfun(@(x) strcmp(x,'NB'),...
                obj.segment_tbl.label);
            figure;
            thresh_specified = (nargin>1);
            if thresh_specified
                control_groups = ...
                    intogroups(obj.segment_tbl(control_idx,:),ths);
                MB_groups = ...
                    intogroups(obj.segment_tbl(MB_idx,:),ths);
                NB_groups = ...
                    intogroups(obj.segment_tbl(NB_idx,:),ths);
                len = numel(ths);
                ths = [0,ths];
            else
                control_groups =...
                    obj.segment_tbl.median_red(control_idx);
                MB_groups = ...
                    obj.segment_tbl.median_red(MB_idx);
                NB_groups = ...
                    obj.segment_tbl.median_red(NB_idx);
                len = 1;
            end
            for i = 1:len
                if thresh_specified
                    subplot(ceil(sqrt(len)),ceil(sqrt(len)),i);
                    cur_controls = control_groups{i};
                    cur_MBs = MB_groups{i};
                    cur_NBs = NB_groups{i};
                else
                    cur_controls = control_groups;
                    cur_MBs = MB_groups;
                    cur_NBs = NB_groups;
                end
                if showmode
                    if ~isempty(cur_controls)
                        a1 = histogram(cur_controls,100,'FaceColor','#8c1515',...
                            'Normalization','probability');
                    end
                    if ~isempty(cur_MBs)
                        hold on;
                        a2 = histogram(cur_MBs,100,'FaceColor','#09425A',...
                            'Normalization','probability');
                    end
                    if ~isempty(cur_NBs)
                        hold on;
                        a3 = histogram(cur_NBs,100,'FaceColor','#77AC30',...
                            'Normalization','probability');
                    end
                else
                    [control_density, control_vals] =...
                        ksdensity(cur_controls);
                    a1 = area(control_vals, ...
                        100*control_density./sum(control_density),...
                        'FaceColor','#8c1515');
                    [max_control,max_control_idx] =...
                        max(100*control_density./sum(control_density));
                    a1.FaceAlpha = 0.5;
                    if ~isempty(cur_MBs)
                        [MB_density, MB_vals] =...
                                ksdensity(cur_MBs);
                        hold on;
                        a2 = area(MB_vals,...
                            100*MB_density./sum(MB_density),...
                            'FaceColor','#09425A');
                        a2.FaceAlpha = 0.5;
                        [max_MB,max_MB_idx] =...
                        max(100*MB_density./sum(MB_density));
                    end
                    if ~isempty(cur_NBs)
                        [NB_density, NB_vals] =...
                            ksdensity(cur_NBs);
                        hold on;
                        a3 = area(NB_vals, ...
                            100*NB_density./sum(NB_density), ...
                            'FaceColor','#77AC30');
                        a3.FaceAlpha = 0.5;
                        [max_NB,max_NB_idx] =...
                        max(100*NB_density./sum(NB_density));
                    end
                
                    xlabel('EB intensity [A.U.]');
                    ylabel('# Vessels [%]');

                    if length(exp_groups) == 3
                        legend([a1,a2, a3],{'control','MB + FUS', 'NB + FUS'});
                    else
                        if ismember('MB', exp_groups)
                            legend([a1,a2],{'control','MB + FUS'});
                        elseif ismember('NB', exp_groups)
                            legend([a1,a3],{'control','NB + FUS'});
                        end
                    end

                    if isnumeric(numstd) && ~isempty(numstd)
                       l1 = xline(mean(cur_controls)+numstd*std(cur_controls),...
                           'LineWidth',2,'LineStyle','--');

                       if length(exp_groups) == 3
                           legend([a1,a2, a3, l1],{'control','MB + FUS','NB + FUS',...
                           ['Control mean + ',num2str(numstd),' SDs']});
                       else
                           if ismember('MB', exp_groups)
                               legend([a1, a2, l1],{'control','MB + FUS',...
                           ['Control mean + ',num2str(numstd),' SDs']});
                           elseif ismember('NB', exp_groups)
                               legend([a1, a3, l1],{'control','NB + FUS',...
                           ['Control mean + ',num2str(numstd),' SDs']});
                           end
                       end
                    end
                end
                xlim([0,1]);
                ylim([0,5]);
                if thresh_specified
                    title(sprintf('%d-%d um diameter',ths(i),ths(i+1)));
                end
                hold off; 
            end
        end
        function diamHist(obj)
            exp_groups = unique(obj.segment_tbl.("label"));
            % histogram of blood vessel diameter. 
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            MB_idx = cellfun(@(x) strcmp(x,'MB'),...
                obj.segment_tbl.label);
            NB_idx = cellfun(@(x) strcmp(x,'NB'),...
                obj.segment_tbl.label);
            control_diams = obj.segment_tbl.median_segment_diam_um(control_idx);
            MB_diams = obj.segment_tbl.median_segment_diam_um(MB_idx);
            NB_diams = obj.segment_tbl.median_segment_diam_um(NB_idx);
            histogram(control_diams,0.5:1:25.5,...
                'Normalization','probability','FaceColor','#8c1515'); 
            hold on;
            histogram(MB_diams,0.5:1:25.5,'Normalization','probability',...
                'FaceColor','#09425A');
            hold on;
            histogram(NB_diams,0.5:1:25.5,'Normalization','probability',...
                'FaceColor','#77AC30');

            if length(exp_groups) == 3
                legend(['Control-',num2str(numel(control_diams)),' total segments']...
                ,['MBs Treatment-',num2str(numel(MB_diams)),' total segments']...
                ,['NBs Treatment-',num2str(numel(NB_diams)),' total segments']);
            else
                if ismember('MB', exp_groups)
                    legend(['Control-',num2str(numel(control_diams)),' total segments'], ...
                        ['MBs Treatment-',num2str(numel(MB_diams)),' total segments'], ...
                        '');
                elseif ismember('NB', exp_groups)
                    legend(['Control-',num2str(numel(control_diams)),' total segments'], ...
                        '', ...
                        ['NBs Treatment-',num2str(numel(NB_diams)),' total segments']);
                end
            end

            
            xlabel('Vessel diameter [um]'); ylabel('% of total vessels');
            xticks(1:25)
            title('Blood vessel diameter histogram'); 
            p = anova1(obj.segment_tbl.median_segment_diam_um, MB_idx)
            xticklabels({'control','MB + FUS'});
            ylabel('Diameter [um]');
        end
        function [perc_tbl_MB, perc_tbl_NB] = openedHist(obj,ths,varargin)
            exp_groups = unique(obj.segment_tbl.("label"));
            if length(exp_groups) == 3
                groups = 0;
            else
                if ismember('MB', exp_groups)
                    groups = 1;
                elseif ismember('NB', exp_groups)
                    groups = 2;
                end
            end

            % plot the histogram of fraction of opened vesseles by diameter
            % Inputs:
            %   ths - array of diameters to be used as diameter groups.
            %       default = [2:10]
            % Name-Value pair arguements:
            %   Intrabrain - logical flag:
            %       0 = plot all brains together (default)
            %       1 = plot each brain seperatly
            %   Errorbars - 'on' or 'off' (default), only shows errorbars
            %       if intrabrain is set to 1
            % Output:
            %   perc_tbl = opening percentage table by dimeter and frame            
            P = inputParser();
            P.addOptional('Intrabrain',0,@(x) sum(ismember(x,[0,1])) == 1);
            P.addOptional('Errorbars','off',...
                @(x) sum(strcmp(x,{'on','off'})) == 1);
            P.parse(varargin{:})
            if nargin < 1
                ths = 2:10;
            end
            intrabrain = P.Results.Intrabrain;
            
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            MB_idx = cellfun(@(x) strcmp(x,'MB'),...
                obj.segment_tbl.label);
            NB_idx = cellfun(@(x) strcmp(x,'NB'),...
                obj.segment_tbl.label);
            control_frames = unique(obj.segment_tbl.image_name(control_idx));
            MB_frames = unique(obj.segment_tbl.image_name(MB_idx));
            NB_frames = unique(obj.segment_tbl.image_name(NB_idx));
            ths = [0, ths];
            len_diam_groups = length(ths)-1;
            n_control_animals = numel(control_frames);
            n_MB_animals = numel(MB_frames);
            n_NB_animals = numel(NB_frames);
            perc_control = zeros(len_diam_groups,n_control_animals);
            perc_MB = zeros(len_diam_groups,n_MB_animals);
            perc_NB = zeros(len_diam_groups,n_NB_animals);
            vessel_count_per_brain_control = perc_control;
            vessel_count_per_brain_MB = perc_MB;
            vessel_count_per_brain_NB = perc_NB;
            for i = 1:len_diam_groups
                for j = 1:n_MB_animals
                    in_group_MB = ...
                        obj.segment_tbl.median_segment_diam_um >= ths(i) &...
                        obj.segment_tbl.median_segment_diam_um < ths(i+1) &...
                        strcmp(obj.segment_tbl.image_name,MB_frames(j));
                    vessel_count_per_brain_MB(i,j) = sum(in_group_MB);
                    open_temp = in_group_MB & obj.segment_tbl.opening;
                    perc_MB(i,j) = 100*(sum(open_temp)/sum(in_group_MB));
                end
                for k = 1:n_NB_animals
                    in_group_NB = ...
                        obj.segment_tbl.median_segment_diam_um >= ths(i) &...
                        obj.segment_tbl.median_segment_diam_um < ths(i+1) &...
                        strcmp(obj.segment_tbl.image_name,NB_frames(k));
                    vessel_count_per_brain_NB(i,k) = sum(in_group_NB);
                    open_temp = in_group_NB & obj.segment_tbl.opening;
                    perc_NB(i,k) = 100*(sum(open_temp)/sum(in_group_NB));
                end
                for p = 1:n_control_animals
                    in_group_control = ...
                        obj.segment_tbl.median_segment_diam_um >= ths(i) &...
                        obj.segment_tbl.median_segment_diam_um < ths(i+1) &...
                        strcmp(obj.segment_tbl.image_name,control_frames(p));
                    vessel_count_per_brain_control(i,p) = sum(in_group_control);
                    open_temp = in_group_control & obj.segment_tbl.opening;
                    perc_control(i,p) = 100*(sum(open_temp)/sum(in_group_control));
                end
            end

            switch intrabrain
                case 0
                    % Preform whole group analysis
                    switch groups
                        case 0
                            b1 = bar(0.75:2:((length(ths)-1)*2), mean(perc_control,2,'omitnan'),0.25,'FaceColor','#8c1515');
                            hold on;
                            b2 = bar(1.25:2:((length(ths)-1)*2), mean(perc_MB,2,'omitnan'),0.25,'FaceColor','#09425A');
                            hold on;
                            b3 = bar(1.75:2:((length(ths)-1)*2), mean(perc_NB,2,'omitnan'),0.25,'FaceColor','#77AC30');
                            hold on;
                            errorbar(0.75:2:((length(ths)-1)*2),mean(perc_control,2,'omitnan'),...
                                        [],std(perc_control,0,2,'omitnan'),'k',...
                                        'LineStyle','none');
                            hold on;
                            errorbar(1.25:2:((length(ths)-1)*2),mean(perc_MB,2,'omitnan'),...
                                        [],std(perc_MB,0,2,'omitnan'),'k',...
                                        'LineStyle','none');
                            hold on;
                            errorbar(1.75:2:((length(ths)-1)*2),mean(perc_NB,2,'omitnan'),...
                                [],std(perc_NB,0,2,'omitnan'),'k',...
                                'LineStyle','none');
                                    
                             % Add significance stars of control vs MB vs NB of same diameter
                            data = [];
                            bubble_type = [];
                            diameter = [];
                            diams = [];
                            for i = 1:numel(ths)-1
                                % save results to table
                                if i == numel(ths)
                                    diam = strcat(string(ths(i)), " to ", string(ths(i+1)));
                                else
                                    diam = strcat(string(ths(i)), " to ", string(ths(i+1)));
                                end
                                diams = [diams diam];
                                
                                data = [data, perc_control(i, :), perc_MB(i, :), perc_NB(i, :)];
                                group_control = repmat(["Control"], 1, length(perc_control(i, :)));
                                group_MB = repmat(["MBs"], 1, length(perc_MB(i, :)));
                                group_NB = repmat(["NBs"], 1, length(perc_NB(i, :)));
                                bubble_type = [bubble_type, group_control ,group_MB, group_NB];
                                group_diameter = repmat([diam], 1, length(perc_control(i, :))+length(perc_MB(i, :))+length(perc_NB(i, :)));
                                diameter = [diameter, group_diameter];
                            end
        
                            % Perform ANOVA
                            [p, ~, stats] = anovan(data,{bubble_type diameter},'model',2,'varnames',{'bubble type','diameter'}, 'Display','off');
                            % Perform post-hoc tests (Tukey's honestly significant difference)
        %                     [c, ~, ~, gnames] = multcompare(stats, 'CType', 'hsd', 'Display','off', 'Dimension', [1, 2]);
                            [c, ~, ~, gnames] = multcompare(stats, 'Display','off', 'Dimension', [1, 2]);
        
                            tbl = array2table(c,"VariableNames", ...
                            ["Group A","Group B","Lower Limit","A-B","Upper Limit","P-value"]);
                            tbl.("Group A")=gnames(tbl.("Group A"));
                            tbl.("Group B")=gnames(tbl.("Group B"));
                            
                            idx_keep = [];
                            p_control_MB = [];
                            p_control_NB = [];
                            p_MB_NB = [];
                            for row=1:height(tbl)
                                if strcmp(tbl.("Group A"){row}(end-5:end), tbl.("Group B"){row}(end-5:end))
                                    idx_keep = [idx_keep, row];
                                    if strcmp(tbl.("Group A"){row}(13), 'C') && strcmp(tbl.("Group B"){row}(13), 'M')
                                        p_control_MB = [p_control_MB, tbl.("P-value")(row)];
                                    elseif strcmp(tbl.("Group A"){row}(13), 'C') && strcmp(tbl.("Group B"){row}(13), 'N')
                                        p_control_NB = [p_control_NB, tbl.("P-value")(row)];
                                    elseif strcmp(tbl.("Group A"){row}(13), 'M') && strcmp(tbl.("Group B"){row}(13), 'N')
                                        p_MB_NB = [p_MB_NB tbl.("P-value")(row)];
                                    end
                                end
                            end
                            tbl =  tbl(idx_keep, :);
                            
                            ymax=0;
                            for i = 1:numel(ths)-1
                                st_MB = sigstars(p_control_MB(i));
                                st_NB = sigstars(p_control_NB(i));
                                st = sigstars(p_MB_NB(i));
                                
                                MB_y_pos = mean(perc_MB(i,:),2,'omitnan') + std(perc_MB(i,:),0,2,'omitnan') + 2;
                                ymax = max([ymax, MB_y_pos + 0.05]);
                                if ~strcmp(st_MB, 'ns')
                                    MB_poses = 1.25:2:((length(ths)-1)*2);
                                    pos = MB_poses(i);
                                    text(pos, MB_y_pos,st_MB, 'Color', '#09425A', 'HorizontalAlignment', 'center', 'FontSize', 12);
                                end
                                
                                NB_y_pos = mean(perc_NB(i,:),2,'omitnan') + std(perc_NB(i,:),0,2,'omitnan') + 2;
                                ymax = max([ymax, NB_y_pos + 0.05]);
                                if ~strcmp(st_NB, 'ns')
                                    NB_poses = 1.75:2:((length(ths)-1)*2);
                                    pos = NB_poses(i);
                                    text(pos,NB_y_pos,st_NB, 'Color', '#77AC30', 'HorizontalAlignment', 'center', 'FontSize', 12);
                                end
        
                            end

                        case 1
                            b1 = bar(0.75:2:((length(ths)-1)*2), mean(perc_control,2,'omitnan'),0.25,'FaceColor','#8c1515');
                            hold on;
                            b2 = bar(1.25:2:((length(ths)-1)*2), mean(perc_MB,2,'omitnan'),0.25,'FaceColor','#09425A');
                            hold on;
                            errorbar(0.75:2:((length(ths)-1)*2),mean(perc_control,2,'omitnan'),...
                                        [],std(perc_control,0,2,'omitnan'),'k',...
                                        'LineStyle','none');
                            hold on;
                            errorbar(1.25:2:((length(ths)-1)*2),mean(perc_MB,2,'omitnan'),...
                                        [],std(perc_MB,0,2,'omitnan'),'k',...
                                        'LineStyle','none');
                                    
                             % Add significance stars of control vs MB vs NB of same diameter
                            data = [];
                            bubble_type = [];
                            diameter = [];
                            diams = [];
                            for i = 1:numel(ths)-1
                                % save results to table
                                if i == numel(ths)
                                    diam = strcat(string(ths(i)), " to ", string(ths(i+1)));
                                else
                                    diam = strcat(string(ths(i)), " to ", string(ths(i+1)));
                                end
                                diams = [diams diam];
                                
                                data = [data, perc_control(i, :), perc_MB(i, :)];
                                group_control = repmat(["Control"], 1, length(perc_control(i, :)));
                                group_MB = repmat(["MBs"], 1, length(perc_MB(i, :)));
                                bubble_type = [bubble_type, group_control ,group_MB];
                                group_diameter = repmat([diam], 1, length(perc_control(i, :))+length(perc_MB(i, :)));
                                diameter = [diameter, group_diameter];
                            end
        
                            % Perform ANOVA
                            [p, ~, stats] = anovan(data,{bubble_type diameter},'model',2,'varnames',{'bubble type','diameter'}, 'Display','off');
                            [c, ~, ~, gnames] = multcompare(stats, 'Display','off', 'Dimension', [1, 2]);
        
                            tbl = array2table(c,"VariableNames", ...
                            ["Group A","Group B","Lower Limit","A-B","Upper Limit","P-value"]);
                            tbl.("Group A")=gnames(tbl.("Group A"));
                            tbl.("Group B")=gnames(tbl.("Group B"));
                            
                            idx_keep = [];
                            p_control_MB = [];
                            for row=1:height(tbl)
                                if strcmp(tbl.("Group A"){row}(end-5:end), tbl.("Group B"){row}(end-5:end))
                                    idx_keep = [idx_keep, row];
                                    if strcmp(tbl.("Group A"){row}(13), 'C') && strcmp(tbl.("Group B"){row}(13), 'M')
                                        p_control_MB = [p_control_MB, tbl.("P-value")(row)];
                                    end
                                end
                            end
                            tbl =  tbl(idx_keep, :);
                            
                            ymax=0;
                            for i = 1:numel(ths)-1
                                st_MB = sigstars(p_control_MB(i));
                                
                                MB_y_pos = mean(perc_MB(i,:),2,'omitnan') + std(perc_MB(i,:),0,2,'omitnan') + 2;
                                ymax = max([ymax, MB_y_pos + 0.05]);
                                if ~strcmp(st_MB, 'ns')
                                    MB_poses = 1.25:2:((length(ths)-1)*2);
                                    pos = MB_poses(i);
                                    text(pos, MB_y_pos,st_MB, 'Color', '#09425A', 'HorizontalAlignment', 'center', 'FontSize', 12);
                                end

                            end

                        case 2
                            b1 = bar(0.75:2:((length(ths)-1)*2), mean(perc_control,2,'omitnan'),0.25,'FaceColor','#8c1515');
                            hold on;
                            b3 = bar(1.25:2:((length(ths)-1)*2), mean(perc_NB,2,'omitnan'),0.25,'FaceColor','#77AC30');
                            hold on;
                            errorbar(0.75:2:((length(ths)-1)*2),mean(perc_control,2,'omitnan'),...
                                        [],std(perc_control,0,2,'omitnan'),'k',...
                                        'LineStyle','none');
                            hold on;
                            errorbar(1.25:2:((length(ths)-1)*2),mean(perc_NB,2,'omitnan'),...
                                        [],std(perc_NB,0,2,'omitnan'),'k',...
                                        'LineStyle','none');
                                    
                             % Add significance stars of control vs NB vs NB of same diameter
                            data = [];
                            bubble_type = [];
                            diameter = [];
                            diams = [];
                            for i = 1:numel(ths)-1
                                % save results to table
                                if i == numel(ths)
                                    diam = strcat(string(ths(i)), " to ", string(ths(i+1)));
                                else
                                    diam = strcat(string(ths(i)), " to ", string(ths(i+1)));
                                end
                                diams = [diams diam];
                                
                                data = [data, perc_control(i, :), perc_NB(i, :)];
                                group_control = repmat(["Control"], 1, length(perc_control(i, :)));
                                group_NB = repmat(["NBs"], 1, length(perc_NB(i, :)));
                                bubble_type = [bubble_type, group_control ,group_NB];
                                group_diameter = repmat([diam], 1, length(perc_control(i, :))+length(perc_NB(i, :)));
                                diameter = [diameter, group_diameter];
                            end
        
                            % Perform ANOVA
                            [p, ~, stats] = anovan(data,{bubble_type diameter},'model',2,'varnames',{'bubble type','diameter'}, 'Display','off');
                            [c, ~, ~, gnames] = multcompare(stats, 'Display','off', 'Dimension', [1, 2]);
        
                            tbl = array2table(c,"VariableNames", ...
                            ["Group A","Group B","Lower Limit","A-B","Upper Limit","P-value"]);
                            tbl.("Group A")=gnames(tbl.("Group A"));
                            tbl.("Group B")=gnames(tbl.("Group B"));
                            
                            idx_keep = [];
                            p_control_NB = [];
                            for row=1:height(tbl)
                                if strcmp(tbl.("Group A"){row}(end-5:end), tbl.("Group B"){row}(end-5:end))
                                    idx_keep = [idx_keep, row];
                                    if strcmp(tbl.("Group A"){row}(13), 'C') && strcmp(tbl.("Group B"){row}(13), 'N')
                                        p_control_NB = [p_control_NB, tbl.("P-value")(row)];
                                    end
                                end
                            end
                            tbl =  tbl(idx_keep, :);
                            
                            ymax=0;
                            for i = 1:numel(ths)-1
                                st_NB = sigstars(p_control_NB(i));
                                
                                NB_y_pos = mean(perc_NB(i,:),2,'omitnan') + std(perc_NB(i,:),0,2,'omitnan') + 2;
                                ymax = max([ymax, NB_y_pos + 0.05]);
                                if ~strcmp(st_NB, 'ns')
                                    NB_poses = 1.25:2:((length(ths)-1)*2);
                                    pos = NB_poses(i);
                                    text(pos, NB_y_pos,st_NB, 'Color', '#77AC30', 'HorizontalAlignment', 'center', 'FontSize', 12);
                                end

                            end
                    end

                case 1
                    subplot(2,2,2)
                    bar(100*perc_MB./max(perc_MB,[],1),0.5);
                    legend(MB_frames)
                    xlabel('Blood vessel diameter [um]'); 
                    xticklabels(generate_xticks(ths(2:end)));
                    ylabel('Open vessel fraction / max Opened vessel fraction');
                    title({'Opened vessel fraction as function of diameter',...
                        'Normalized by maximal percentage'});
                    subplot(2,2,3)
                    bar(perc_MB./sum(vessel_count_per_brain,1),0.5);
                    legend(MB_frames)
                    xlabel('Blood vessel diameter [um]'); 
                    xticklabels(generate_xticks(ths(2:end)));
                    ylabel('Total number of opened vessels');
                    title({'Opened vessel fraction as function of diameter',...
                        'Normalized by total number of vessels in the brain'});
                    subplot(2,2,4)
                    bar(perc_MB./vessel_count_per_brain,0.5);
                    legend(MB_frames)
                    xlabel('Blood vessel diameter [um]'); 
                    xticklabels(generate_xticks(ths(2:end)));
                    ylabel('Total number of opened vessels');
                    title({'Opened Vessel Fraction as Function of Vessel Diameter',...
                        'Normalized by number of vessels in group'});
                    subplot(2,2,1)
                    bar(perc_MB,0.5);
                    legend(MB_frames)
            end
            xlabel('Blood vessel diameter [\mum]'); 
            xticks(1:2:(length(ths)*2));
            xticklabels(generate_xticks(ths(2:end)));
            ylabel('Open vessel fraction [%]');
            title('Opened Vessel Fraction as Function of Vessel Diameter');

            if groups == 0
                legend([b1, b2, b3], 'Control', 'MB', 'NB')
            elseif groups == 1
                legend([b1, b2], 'Control', 'MB')
            elseif groups == 2
                legend([b1, b3], 'Control', 'NB')
            end
            ylim([0 ymax+2])
            
            perc_tbl_MB = array2table(perc_MB,'VariableNames',MB_frames,...
                'RowNames',generate_xticks(ths(2:end)));
            perc_tbl_NB = array2table(perc_NB,'VariableNames',NB_frames,...
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
            treatment_animals = unique(animal_names(~control_idx));
            regions = unique(region(~control_idx));
            counts = zeros(numel(regions),numel(treatment_animals));
            for i = 1:numel(regions)
                for j = 1:numel(treatment_animals)
                    counts(i,j) = sum(strcmp(region,regions(i)) &...
                        strcmp(animal_names,treatment_animals(j)));
                end
            end
            figure;
            bar(counts,0.5);
            legend(treatment_animals)
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
    vertcat(tbl.median_red{:,:}),vertcat(tbl.segment_len_um{:,:}),...
    'VariableNames',...
    {'image_name','median_segment_diam_um','median_red','len'}); 
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