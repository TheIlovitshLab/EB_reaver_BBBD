% Wrapper to perform EB analysis on entire folder for multiple initial
% distances and end distances, for each pair it will generate the
% normalized and un-normalized 
initial_distances = [0,2,5,10];
widths = [1,5,10];
control_dir = 'C:\Users\Admin\Documents\Studies\Masters\Research\Experiment results\Fluorescent microscopy\for RAVE\all data - 16 bit\combined controls';
test_dir = 'C:\Users\Admin\Documents\Studies\Masters\Research\Experiment results\Fluorescent microscopy\for RAVE\all data - 16 bit\263kpa';
csv_dir = 'C:\Users\Admin\Documents\Studies\Masters\Research\Experiment results\Fluorescent microscopy\for RAVE\all data - 16 bit\excel files for graphpad analysis\Longer then 10um';
% low_bound = 1/0.29288;
for i = initial_distances
    for w = widths
        %Analyzing folder
%         non_norm_control_file_path =...
%             EB_analysis_entire_folder(w,control_dir,0,i);
%         non_norm_test_file_path =...
%             EB_analysis_entire_folder(w,test_dir,0,i);
        norm_control_file_path =...
            EB_analysis_entire_folder(w,control_dir,1,i);
        norm_test_file_path =...
            EB_analysis_entire_folder(w,test_dir,1,i);
        %If analysis already exists, just load files
%         if i == 0
%             non_norm_control_file_path = fullfile(control_dir,...
%                 ['EB_analysis_',num2str(w),'px.mat']);
%             non_norm_test_file_path = fullfile(test_dir,...
%                 ['EB_analysis_',num2str(w),'px.mat']);
%             norm_control_file_path = fullfile(control_dir,...
%                 ['EB_analysis_',num2str(w),'px_N.mat']);
%             norm_test_file_path = fullfile(test_dir,...
%                 ['EB_analysis_',num2str(w),'px_N.mat']);
%         else
%             norm_control_file_path = fullfile(control_dir,...
%                 ['EB_analysis__from_',num2str(i),'_',num2str(w),'px_N.mat']);
%             non_norm_control_file_path = fullfile(control_dir,...
%                 ['EB_analysis__from_',num2str(i),'_',num2str(w),'px.mat']);
%             norm_test_file_path = fullfile(test_dir,...
%                 ['EB_analysis__from_',num2str(i),'_',num2str(w),'px_N.mat']);
%             non_norm_test_file_path = fullfile(test_dir,...
%                 ['EB_analysis__from_',num2str(i),'_',num2str(w),'px.mat']);
%         end
        %
        norm_results = EB_analysis(norm_control_file_path,norm_test_file_path);
%         non_norm_results = EB_analysis(non_norm_control_file_path,non_norm_test_file_path);
        %Writing to csv
%         non_norm_results.writecsv([2:10],0,...
%             fullfile(csv_dir,...
%             ['Control_from',num2str(i),'px_to_',num2str(i+w),'px.csv']),...
%             fullfile(csv_dir,...
%             ['Test_from',num2str(i),'px_to_',num2str(i+w),'px.csv']));
        norm_results.writecsv([2:10],0,...
            fullfile(csv_dir,...
            ['Control_from',num2str(i),'px_to_',num2str(i+w),'px_N.csv']),...
            fullfile(csv_dir,...
            ['Test_from',num2str(i),'px_to_',num2str(i+w),'px_N.csv']));
        %Plotting
%         figure;
%         subplot(2,2,1);
%         non_norm_results.barplot([4,8,10],-1);
%         title(['From ',num2str(i),'px to ',num2str(i+w),'px']);
%         subplot(2,2,2);
%         non_norm_results.barplot([4,8,10],1);
%         title(['From ',num2str(i),'px to ',num2str(i+w),'px']);
%         subplot(2,2,3);
%         norm_results.barplot([4,8,10],-1);
%         title({['From ',num2str(i),' px to ',num2str(i+w),' px'],'Normalized'});
%         subplot(2,2,4);
%         norm_results.barplot([4,8,10],1);
%         title({['From ',num2str(i),' px to ',num2str(i+w),' px'],'Normalized'});
%         title(['From',num2str(i),'px to ',num2str(i+w),'px']);
%         title({['From',num2str(i),'px_to_',num2str(i+w),'px'],'Normalized'});
%         saveas(gcf, fullfile(csv_dir,['From',num2str(i),'px_to_',num2str(i+w),'px.jpg']));
%         saveas(gcf, fullfile(csv_dir,['From_',num2str(i),'px_to_',num2str(i+w),'px_diameter_trends.jpg']));
    end
end