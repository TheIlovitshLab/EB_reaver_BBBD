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
            area_idx = cellfun(@(x) contains(lower(x),lower(area_name)),...
                obj.segment_tbl.image_name);
            new_obj = obj;
            new_obj.segment_tbl(~area_idx,:) = [];
        end
        function new_obj = normalize_red(obj)
            % Create a new EB_analysis object where the data is normalized
            % by the linear equation that fits the control data
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            control_median_diams =...
                obj.segment_tbl.median_segment_diam_um(control_idx);
            control_eb = obj.segment_tbl.avg_red_px_val(control_idx);
            [f,~] = ...
                fit(control_median_diams, control_eb,'poly1');
            vals = coeffvalues(f); % Get the linear model coefficients
            new_obj = obj;
            new_obj.segment_tbl.avg_red_px_val =...
                (new_obj.segment_tbl.avg_red_px_val-vals(2))./vals(1);
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
        %% Statistical analysis
        function [p,tbl,stats] = anova(obj)
            [p,tbl,stats] = anovan(obj.segment_tbl.avg_red_px_val,...
                {obj.segment_tbl.median_segment_diam_um, obj.segment_tbl.label},...
                'continuous',[1],'varnames',{'diameter','label'},...
                'model','interaction');
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
%                             'c','#8c1515'
            hold on;
            scatter(...
                obj.segment_tbl.median_segment_diam_um(~control_idx),...
                obj.segment_tbl.avg_red_px_val(~control_idx));
%                 'c','#09425A');
            legend('control','MB + FUS');
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
            errorbar(control_red,control_red_std,'Color','#8c1515');...
                hold on; errorbar(test_red,test_red_std,'Color','#09425A');
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
            ylabel('Average red pixel intensity [8bit]');
        end
        function boxplot(obj,ths)
            % Box plot with 2 colors. one representing the control group
            % and the other representing the test group.
            % Inputs:
            %   ths (optional)- array of diameters to be used as x-axis.
            %       vessels with diameter larger than ths(end) will not be
            %       presented.
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            if nargin < 2
                ths = 0;
                median_control_eb = ...
                    obj.segment_tbl.avg_red_px_val(control_idx);
                median_test_eb = ...
                    obj.segment_tbl.avg_red_px_val(~control_idx);
                boxplot(median_control_eb,...
                    'Positions',10,...
                    'Widths',5);
                hold on;
                boxplot(median_test_eb,...
                    'Positions',20,...
                    'Widths',5);
                xticks([10,20]);
                xticklabels({'Control','Test'});
            else
                [median_control_eb,~] = ...
                    intogroups(obj.segment_tbl.avg_red_px_val(control_idx),...
                    obj.segment_tbl.median_segment_diam_um(control_idx),ths);
                [median_test_eb,~] = ...
                    intogroups(obj.segment_tbl.avg_red_px_val(~control_idx),...
                    obj.segment_tbl.median_segment_diam_um(~control_idx),ths);
                boxplot2(median_control_eb,...
                    'Positions',(ths-1).*20+10,...
                    'Widths',5*ones(1,length(ths)+1));
                hold on;
                boxplot2(median_test_eb,...
                    'Positions',(ths-1).*20+15,...
                    'Widths',5*ones(1,length(ths)+1));
                xticks((ths-1).*20+12.5);
                xticklabels(cellfun(@(x) num2str(x),num2cell(ths),'UniformOutput',false));
            end

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
                    obj.segment_tbl.avg_red_px_val(control_idx);
                test_groups = ...
                    obj.segment_tbl.avg_red_px_val(~control_idx);
                control_mu_median = [mean(control_groups);
                    std(control_groups)];
                test_mu_median = [mean(test_groups);
                    std(test_groups)];
                control_groups = rmoutliers(control_groups);
                test_groups = rmoutliers(test_groups);
                ths = 0;
            else
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
                control_groups = cellfun(@(x) rmoutliers(x),...
                    control_groups,'UniformOutput',false);
                test_groups = cellfun(@(x) rmoutliers(x),...
                    test_groups,'UniformOutput',false);
            end
            switch groups
                case 1  % only test
                    bar(1:2:(length(ths)*2+1),test_mu_median(1,:),0.5,...
                        'FaceColor','#09425A');
                    hold on;
                    errorbar(1:2:(length(ths)*2+1),test_mu_median(1,:),...
                        test_mu_median(2,:),test_mu_median(2,:),'LineStyle','none'); 
                    xticks(1:2:(length(ths)*2+1));
                    xticklabels(generate_xticks(ths));
                    title({'EB intensity in perivascular area as function of the vessel diameter',...
                        [num2str(obj.n_px*obj.UM_PX),' um perivascular area']});
                    xlabel('Vessel diameter [um]');
                    ylabel('Average red intensity in perivascular area [8bit]')

                    for i = 2:numel(ths)
                       [~,p] = ttest2(test_groups{1},test_groups{i});
                       maxy = max(sum(test_mu_median(1:2,:),1))*(1+i/20);
                       line([0.5,(i-1)*2+1.5],maxy*[1,1]);
                       st = sigstars(p);
                       pos = (i-1)*2+1.5-length(st)*0.25;
                       if strcmp(st,'ns')
                           y_pos = maxy*1.02;
                       else
                           y_pos = maxy*1.01;
                       end
                       text(pos,y_pos,st);
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
                        b1 = bar(0.75:2:(length(ths)*2+0.75),...
                            control_mu_median(1,:),0.25,...
                            'FaceColor','#8c1515');
                        hold on;
                        b2 =bar(1.25:2:(length(ths)*2+1.25),...
                            test_mu_median(1,:),0.25,...
                            'FaceColor','#09425A');
                        errorbar(0.75:2:(length(ths)*2+0.75),control_mu_median(1,:),...
                            control_mu_median(2,:),control_mu_median(2,:),'k',...
                            'LineStyle','none');
                        errorbar(1.25:2:(length(ths)*2+1.25),test_mu_median(1,:),...
                            test_mu_median(2,:),test_mu_median(2,:),'k',...
                            'LineStyle','none'); 
                        xticks(1:2:(length(ths)*2+1));
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
                    title({'EB intensity in perivascular area as function of the vessel diameter',...
                        [num2str(obj.n_px*obj.UM_PX),' um perivascular area']});
                    ylabel('Average red intensity in perivascular area [8bit]')

                case 0  % diffrence
                    bar(0.75:2:(length(ths)*2+0.75),...
                    test_mu_median(1,:)-control_mu_median(1,:),0.25,...
                    'FaceColor','#09425A');
                    xticks(1:2:(length(ths)*2+1));
                    xticklabels(generate_xticks(ths));
                    title({'treatment-control',...
                        [num2str(obj.n_px*obj.UM_PX),' um perivascular area']});
                    xlabel('Vessel diameter [um]');
                    ylabel('test-control difference in average red intensity [8bit]')
                case -1  % only control
                    bar(1:2:(length(ths)*2+1),control_mu_median(1,:),0.5,...
                        'FaceColor','#09425A');
                    hold on;
                    errorbar(1:2:(length(ths)*2+1),control_mu_median(1,:),...
                        control_mu_median(2,:),control_mu_median(2,:),...
                        'LineStyle','none'); 
                    xticks(1:2:(length(ths)*2+1));
                    xticklabels(generate_xticks(ths));
                    title({'EB intensity in perivascular area as function of the vessel diameter',...
                        [num2str(obj.n_px*obj.UM_PX),' um perivascular area']});
                    xlabel('Vessel diameter [um]');
                    ylabel('Average red intensity in perivascular area [8bit]')

                    for i = 2:numel(ths)
                       [~,p] = ttest2(control_groups{1},control_groups{i});
                       maxy = max(sum(control_mu_median,1))*(0.8+i/20);
                       line([0.5,(i-1)*2+1.5],maxy*[1,1]);
                       st = sigstars(p);
                       pos = (i-1)*2+1.5-length(st)*0.25;
                       text(pos,maxy*1.01,st);
                    end
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
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            figure;
            if nargin > 2 % Thresholds specified
                [control_groups,~] = ...
                    intogroups(obj.segment_tbl.avg_red_px_val(control_idx),...
                    obj.segment_tbl.median_segment_diam_um(control_idx),ths);
                [test_groups,~] = ...
                    intogroups(obj.segment_tbl.avg_red_px_val(~control_idx),...
                    obj.segment_tbl.median_segment_diam_um(~control_idx),ths);   
                            len = numel(ths);
                ths = [0,ths];
                for i = 1:len-1
                    subplot(ceil(sqrt(len)),ceil(sqrt(len)),i);
                    histogram(control_groups{i},100,'FaceColor','#8c1515');
                    hold on;
                    histogram(test_groups{i},100,'FaceColor','#09425A');
    %                 xlim([0,155]);
                    xlabel('EB intensity [AU]');
                    ylabel('# of blood vessels');
                    legend('control','MB + FUS');
                    if nargin == 3
                       controls = control_groups{i};
                       xline(mean(controls)+numstd*std(controls));
                       legend('control','MB + FUS',...
                           ['Control mean +',num2str(numstd),'std']);
                    end
                    hold off; 
                    title(sprintf('%d-%d um diameter',ths(i),ths(i+1)));
                end
            else
                control_groups =...
                    obj.segment_tbl.avg_red_px_val(control_idx);
                test_groups = ...
                    obj.segment_tbl.avg_red_px_val(~control_idx);
                histogram(control_groups,100,'FaceColor','#8c1515');
                hold on;
                histogram(test_groups,100,'FaceColor','#09425A');
                xlabel('EB intensity [AU]');
                ylabel('# of blood vessels');
                legend('Control','Test');
                hold off; 
                title({'Average red intenity in perivascular area',...
                    'in all vessel diameters'}); 
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
        end
        function openedHist(obj,ths,intrabrain)
            % plot the histogram of fraction of opened vesseles by diameter
            % Inputs:
            %   ths - array of diameters to be used as diameter ..
            %       groups.
            %   intrabrain - logical flag:
            %       0 = plot all brains together,
            %       1 = plot each brain seperatly
            if nargin < 2
               ths = 2:15;
            end
            control_idx = cellfun(@(x) strcmp(x,'control'),...
                obj.segment_tbl.label);
            frame_label = cellfun(@(x) textscan(x,'%s','Delimiter','_'),...
                obj.segment_tbl.image_name);
            animal_names = cellfun(@(x) x{1},frame_label,'UniformOutput',...
                false);
            test_animals = unique(animal_names(~control_idx));
            ths = [0, ths];
            len_diam_groups = length(ths)-1;
            n_animals = numel(test_animals);
            perc = zeros(len_diam_groups,n_animals);
            vessel_count_per_brain = perc;
            for i = 1:len_diam_groups
                for j = 1:n_animals
                    in_group = ...
                        obj.segment_tbl.median_segment_diam_um >= ths(i) &...
                        obj.segment_tbl.median_segment_diam_um < ths(i+1) &...
                        strcmp(animal_names,test_animals(j));
                    vessel_count_per_brain(i,j) = sum(in_group);
                    open_temp = in_group & obj.segment_tbl.opening;
                    perc(i,j) = 100*(sum(open_temp)/sum(in_group));
                end
            end
            switch intrabrain
                case 0
                    % Preform whole group analysis
                    bar(mean(perc,2),0.5,'FaceColor','#009779');
                    hold on;
                    errorbar(1:len_diam_groups,mean(perc,2),...
                                std(perc,0,2),std(perc,0,2),'k',...
                                'LineStyle','none');
                    for i = 1:len_diam_groups-1
                       [~,p] = ttest2(perc(i,:),perc(i+1,:));
                       maxy = max([max(perc(i,:)),max(perc(i+1,:))]);
                       x_cord = i-1;
                       line([0.75,2.25]+x_cord,(maxy*1.05)*[1,1]);
                       text(x_cord+0.75,maxy*1.08,sigstars(p));
                    end
                case 1
                    subplot(2,2,2)
                    bar(100*perc./max(perc,[],1),0.5);
                    legend(test_animals)
                    xlabel('Blood vessel diameter [um]'); 
                    xticklabels(generate_xticks(ths(2:end)));
                    ylabel('Open vessel fraction / max Opened vessel fraction');
                    title({'Opened vessel fraction as function of diameter',...
                        'Normalized by maximal percentage'});
                    subplot(2,2,3)
                    bar(perc./sum(vessel_count_per_brain,1),0.5);
                    legend(test_animals)
                    xlabel('Blood vessel diameter [um]'); 
                    xticklabels(generate_xticks(ths(2:end)));
                    ylabel('Total number of opened vessels');
                    title({'Opened vessel fraction as function of diameter',...
                        'Normalized by total number of vessels in the brain'});
                    subplot(2,2,4)
                    bar(perc./vessel_count_per_brain,0.5);
                    legend(test_animals)
                    xlabel('Blood vessel diameter [um]'); 
                    xticklabels(generate_xticks(ths(2:end)));
                    ylabel('Total number of opened vessels');
                    title({'Opened vessel fraction as function of diameter',...
                        'Normalized by number of vessels in group'});
                    subplot(2,2,1)
                    bar(perc,0.5);
                    legend(test_animals)
            end
            xlabel('Blood vessel diameter [um]'); 
            xticklabels(generate_xticks(ths(2:end)));
            ylabel('Open vessel fraction [%]');
            title('Opened vessel fraction as function of diameter'); 
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