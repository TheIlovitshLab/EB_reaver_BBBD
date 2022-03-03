classdef EB_analysis
    properties
        control_tbl 
        test_tbl 
        n_px 
        control_median_diams
        control_eb
        test_median_diams
        test_eb
        um_px = 0.29288;    % constant
    end
    methods
        % constructor
        function obj = EB_analysis(parent)
            if nargin < 1   % no parent object
                [file1,folder1] = uigetfile('*.mat','Choose control analysis file');
                control = load(fullfile(folder1,file1));
                obj.control_tbl = control.res.table;
                [file2,folder2] = uigetfile('*.mat','Choose treatment analysis file');
                test = load(fullfile(folder2,file2));  
                obj.test_tbl = test.res.table;
                obj.n_px = control.res.n_px;
            else
                obj = parent;
            end
            obj.control_median_diams = vertcat(obj.control_tbl.median_segment_diam_um{:,:});
            obj.control_eb = vertcat(obj.control_tbl.avg_red_px_val{:,:});
            obj.test_median_diams = vertcat(obj.test_tbl.median_segment_diam_um{:,:});
            obj.test_eb = vertcat(obj.test_tbl.avg_red_px_val{:,:});
        end
        %% Create sub object for specific region
        function new_obj = subarea(obj,area_name)
            control_area_idx = cellfun(@(x) contains(lower(x),lower(area_name)),obj.control_tbl.image_name);
            test_area_idx = cellfun(@(x) contains(lower(x),lower(area_name)),obj.test_tbl.image_name);
            new_obj = obj;
            new_obj.control_tbl(~control_area_idx,:) = [];
            new_obj.test_tbl(~test_area_idx,:) = [];
            new_obj = EB_analysis(new_obj);
        end
        %% Plotting functions
        function scatterPlot(obj)
            scatter(obj.control_median_diams,obj.control_eb);
            hold on;
            scatter(obj.test_median_diams,obj.test_eb);
            legend('control','treatment');
            title('extravasation as function of median diameter');
            xlabel('median segment diameter [um]'); 
            ylabel('Average red pixel intensity');
        end
        function boxplot(obj,ths)
            if nargin < 2
                ths = 2:15;
            end
            median_control_eb = intogroups(obj.control_eb,obj.control_median_diams,ths);
            median_test_eb = intogroups(obj.test_eb,obj.test_median_diams,ths);

            boxplot2(median_control_eb,'Colors','b','Positions',(ths-1).*20+10,...
                'Widths',5*ones(1,length(ths)+1));
            hold on;
            boxplot2(median_test_eb,'Colors','k','Positions',(ths-1).*20+15,...
                'Widths',5*ones(1,length(ths)+1));
            xticks((ths-1).*20+12.5);
            xticklabels(cellfun(@(x) num2str(x),num2cell(ths),'UniformOutput',false));

            title({'EB intensity in perivascular area as function of the vessel diameter',...
                [num2str(obj.n_px*obj.um_px),' um perivascular area']});

            ylabel('Average red pixel intensity');
        end
        function barplot(obj,ths,groups)
            if nargin < 3
                groups = 0;
            end
            if nargin < 2
                ths = 2:15;
            end
            control_groups = intogroups(obj.control_eb,obj.control_median_diams,ths);
            test_groups = intogroups(obj.test_eb,obj.test_median_diams,ths);
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
                    xticks(ths.*2-1);
                    xticklabels(cellfun(@(x) num2str(x),num2cell(ths),'UniformOutput',false));
                    title({'EB intensity in perivascular area as function of the vessel diameter',...
                        [num2str(obj.n_px*obj.um_px),' um perivascular area']});
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
                case 2  % both groups
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
                        [num2str(obj.n_px*obj.um_px),' um perivascular area']});
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
                case 0  % diffrence
                    bar(0.75:2:(length(ths)*2+0.75),...
                    test_mu_median(1,:)-control_mu_median(1,:),0.25,'b');
                    xticks(ths.*2-1);
                    xticklabels(cellfun(@(x) num2str(x),num2cell(ths),'UniformOutput',false));
                    title({'test-control',...
                        [num2str(obj.n_px*obj.um_px),' um perivascular area']});
                    xlabel('Vessel diameter [um]');
                    ylabel('test-control difference in median red intensity [16bit]')
            end
        end
        function redDistrebution(obj,ths)
            if nargin < 2
                ths = [2:10,25];
            end
            control_groups = intogroups(obj.control_eb,obj.control_median_diams,ths);
            test_groups = intogroups(obj.test_eb,obj.test_median_diams,ths);
            figure;
            for i = 1:numel(ths)
                subplot(ceil(sqrt(numel(ths))),ceil(sqrt(numel(ths))),i);
                histogram(control_groups{i},100); hold on; histogram(test_groups{i},100);
                hold off; legend('control','test');
                title(num2str(ths(i)));
            end
        end
        function diamHist(obj)
            histogram(obj.control_median_diams,0.5:1:25.5); hold on;
            histogram(obj.test_median_diams,0.5:1:25.5);
            legend('Control','Treatment');
            xlabel('Vessel diameter [um]'); ylabel('Count');
            xticks(1:25)
            title('Blood vessel diameter histogram'); 
        end
    end
end
